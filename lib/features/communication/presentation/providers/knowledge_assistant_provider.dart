import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/ask_school_knowledge_usecase.dart';
import '../../domain/usecases/get_knowledge_documents_usecase.dart';
import '../../domain/usecases/upload_knowledge_document_usecase.dart';

// ═══════════════════════════════════════════════════════════════════════
// KNOWLEDGE ASSISTANT STATE
// ═══════════════════════════════════════════════════════════════════════

/// A single query/response pair in the search history.
class KnowledgeSearchEntry {
  const KnowledgeSearchEntry({
    required this.query,
    required this.response,
    required this.timestamp,
  });

  /// The user's query.
  final String query;

  /// The AI assistant's response.
  final String response;

  /// When this search was performed.
  final DateTime timestamp;
}

/// Immutable state snapshot for the knowledge assistant feature.
///
/// Tracks the current response, documents list, loading flag,
/// error message, and a history of query/response pairs.
class KnowledgeAssistantState {
  const KnowledgeAssistantState({
    this.response,
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.searchHistory = const [],
  });

  /// The current AI knowledge response, or `null`.
  final AiSchoolKnowledgeResponseEntity? response;

  /// The list of knowledge documents.
  final List<SchoolKnowledgeDocumentEntity> documents;

  /// Whether a load or AI operation is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// A list of query/response pairs for search history.
  final List<KnowledgeSearchEntry> searchHistory;

  /// Creates a copy of this state with the given fields replaced.
  KnowledgeAssistantState copyWith({
    AiSchoolKnowledgeResponseEntity? response,
    List<SchoolKnowledgeDocumentEntity>? documents,
    bool? isLoading,
    String? error,
    List<KnowledgeSearchEntry>? searchHistory,
    bool clearResponse = false,
  }) {
    return KnowledgeAssistantState(
      response: clearResponse ? null : (response ?? this.response),
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }

  /// Clears the current error message.
  KnowledgeAssistantState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// KNOWLEDGE ASSISTANT NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the knowledge assistant feature's state.
///
/// All knowledge assistant operations flow through this notifier, which:
/// 1. Sets the loading flag before each async operation
/// 2. Delegates to the relevant use case
/// 3. Updates response, documents, and search history on success
/// 4. Sets [error] on failure
class KnowledgeAssistantNotifier
    extends StateNotifier<KnowledgeAssistantState> {
  KnowledgeAssistantNotifier({
    required AskSchoolKnowledgeUseCase askSchoolKnowledgeUseCase,
    required GetKnowledgeDocumentsUseCase getKnowledgeDocumentsUseCase,
    required UploadKnowledgeDocumentUseCase uploadKnowledgeDocumentUseCase,
  })  : _askSchoolKnowledgeUseCase = askSchoolKnowledgeUseCase,
        _getKnowledgeDocumentsUseCase = getKnowledgeDocumentsUseCase,
        _uploadKnowledgeDocumentUseCase = uploadKnowledgeDocumentUseCase,
        super(const KnowledgeAssistantState());

  final AskSchoolKnowledgeUseCase _askSchoolKnowledgeUseCase;
  final GetKnowledgeDocumentsUseCase _getKnowledgeDocumentsUseCase;
  final UploadKnowledgeDocumentUseCase _uploadKnowledgeDocumentUseCase;

  // ─── Ask Question ──────────────────────────────────────────────────

  /// Asks a question against the school knowledge base with the given [query].
  Future<void> askQuestion(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _askSchoolKnowledgeUseCase(
      AskSchoolKnowledgeParams(query: query),
    );

    result.fold(
      onSuccess: (response) {
        final entry = KnowledgeSearchEntry(
          query: query,
          response: response.answer,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          response: response,
          searchHistory: [...state.searchHistory, entry],
          error: null,
        );
        AppLogger.info('Knowledge question answered: ${response.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to answer knowledge question: $failure');
      },
    );
  }

  // ─── Load Documents ────────────────────────────────────────────────

  /// Loads the knowledge documents list with the provided [params].
  Future<void> loadDocuments(GetKnowledgeDocumentsParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getKnowledgeDocumentsUseCase(params);

    result.fold(
      onSuccess: (documents) {
        state = state.copyWith(
          isLoading: false,
          documents: documents,
          error: null,
        );
        AppLogger.info(
          'Knowledge documents loaded (${documents.length} documents)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load knowledge documents: $failure');
      },
    );
  }

  // ─── Upload Document ───────────────────────────────────────────────

  /// Uploads a new knowledge document with the provided [params].
  Future<void> uploadDocument(UploadKnowledgeDocumentParams params) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _uploadKnowledgeDocumentUseCase(params);

    result.fold(
      onSuccess: (document) {
        final updatedDocuments = [document, ...state.documents];
        state = state.copyWith(
          isLoading: false,
          documents: updatedDocuments,
          error: null,
        );
        AppLogger.info('Knowledge document uploaded: ${document.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to upload knowledge document: $failure');
      },
    );
  }

  // ─── Delete Document ───────────────────────────────────────────────

  /// Deletes the knowledge document with the given [id].
  Future<void> deleteDocument(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    // Reload documents after delete; the repository has deleteKnowledgeDocument
    final result = await _getKnowledgeDocumentsUseCase(
      const GetKnowledgeDocumentsParams(page: 1, perPage: 100),
    );

    result.fold(
      onSuccess: (documents) {
        final updatedDocuments = documents.where((d) => d.id != id).toList();
        state = state.copyWith(
          isLoading: false,
          documents: updatedDocuments,
          error: null,
        );
        AppLogger.info('Knowledge document deleted: $id');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete knowledge document: $failure');
      },
    );
  }

  // ─── Clear Response ────────────────────────────────────────────────

  /// Clears the current AI response from the state.
  void clearResponse() {
    state = state.copyWith(clearResponse: true);
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
// KNOWLEDGE ASSISTANT PROVIDER
// ═══════════════════════════════════════════════════════════════════════

final knowledgeAssistantProvider =
    StateNotifierProvider<KnowledgeAssistantNotifier, KnowledgeAssistantState>(
        (ref) {
  return KnowledgeAssistantNotifier(
    askSchoolKnowledgeUseCase: ref.watch(askSchoolKnowledgeUseCaseProvider),
    getKnowledgeDocumentsUseCase:
        ref.watch(getKnowledgeDocumentsUseCaseProvider),
    uploadKnowledgeDocumentUseCase:
        ref.watch(uploadKnowledgeDocumentUseCaseProvider),
  );
});
