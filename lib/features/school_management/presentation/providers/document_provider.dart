import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the document listing feature.
class DocumentListState {
  const DocumentListState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.typeFilter,
    this.categoryFilter,
    this.searchQuery,
  });

  /// The list of documents.
  final List<DocumentEntity> documents;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by document type.
  final DocumentType? typeFilter;

  /// Filter by document category.
  final String? categoryFilter;

  /// Active search query for filtering documents.
  final String? searchQuery;

  /// Number of documents currently loaded.
  int get loadedCount => documents.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  DocumentListState copyWith({
    List<DocumentEntity>? documents,
    bool? isLoading,
    String? error,
    DocumentType? typeFilter,
    String? categoryFilter,
    String? searchQuery,
  }) {
    return DocumentListState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      typeFilter: typeFilter ?? this.typeFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Clears the current error message.
  DocumentListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the document list feature's state.
class DocumentListNotifier extends StateNotifier<DocumentListState> {
  DocumentListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const DocumentListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  // ─── Load Documents ────────────────────────────────────────────────

  /// Loads documents for a school with optional filters.
  Future<void> loadDocuments({
    required String schoolId,
    DocumentType? documentType,
    String? category,
    String? searchQuery,
    bool? isPublic,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getDocuments(
      schoolId: schoolId,
      documentType: documentType ?? state.typeFilter,
      category: category ?? state.categoryFilter,
      searchQuery: searchQuery ?? state.searchQuery,
      isPublic: isPublic,
      page: page,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (documents) {
        state = state.copyWith(
          isLoading: false,
          documents: documents,
          error: null,
        );
        AppLogger.info('Loaded ${documents.length} documents');
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

  // ─── Create Document ───────────────────────────────────────────────

  /// Creates a new document.
  Future<void> createDocument(DocumentEntity document) async {
    final result = await _repository.createDocument(document);

    result.fold(
      onSuccess: (createdDocument) {
        final updatedList = [createdDocument, ...state.documents];
        state = state.copyWith(documents: updatedList, error: null);
        AppLogger.info('Document created: ${createdDocument.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create document: $failure');
      },
    );
  }

  // ─── Delete Document ───────────────────────────────────────────────

  /// Deletes a document by its ID.
  Future<void> deleteDocument(String documentId) async {
    final result = await _repository.deleteDocument(documentId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.documents.where((d) => d.id != documentId).toList();
        state = state.copyWith(documents: updatedList, error: null);
        AppLogger.info('Document deleted: $documentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete document: $failure');
      },
    );
  }

  // ─── Download Document ─────────────────────────────────────────────

  /// Increments the download count for a document.
  Future<void> downloadDocument(String documentId) async {
    final result = await _repository.incrementDownloadCount(documentId);

    result.fold(
      onSuccess: (_) {
        final updatedList = state.documents.map((d) {
          if (d.id == documentId) {
            return d.copyWith(downloadCount: d.downloadCount + 1);
          }
          return d;
        }).toList();
        state = state.copyWith(documents: updatedList, error: null);
        AppLogger.info('Document download recorded: $documentId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to record download: $failure');
      },
    );
  }

  // ─── Set Filters ───────────────────────────────────────────────────

  /// Sets the document type filter.
  void setTypeFilter(DocumentType? type) {
    state = state.copyWith(typeFilter: type);
  }

  /// Sets the category filter.
  void setCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
  }

  /// Sets the search query.
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [DocumentListNotifier] and its [DocumentListState].
final documentListProvider =
    StateNotifierProvider<DocumentListNotifier, DocumentListState>((ref) {
  return DocumentListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
