import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/content_usecases.dart';
import '../../domain/usecases/monitoring_usecases.dart';

// ─── Filter State ───────────────────────────────────────────────────────────

class ContentFilterState extends Equatable {
  final String? subjectId;
  final String? educationalLevelId;
  final String? topicId;
  final ContentType? contentType;
  final DifficultyLevel? difficultyLevel;
  final ContentStatus? status;
  final String? searchTerm;

  const ContentFilterState({
    this.subjectId,
    this.educationalLevelId,
    this.topicId,
    this.contentType,
    this.difficultyLevel,
    this.status,
    this.searchTerm,
  });

  ContentFilterState copyWith({
    String? subjectId,
    String? educationalLevelId,
    String? topicId,
    ContentType? contentType,
    DifficultyLevel? difficultyLevel,
    ContentStatus? status,
    String? searchTerm,
    bool clearSubjectId = false,
    bool clearEducationalLevelId = false,
    bool clearTopicId = false,
    bool clearContentType = false,
    bool clearDifficultyLevel = false,
    bool clearStatus = false,
    bool clearSearchTerm = false,
  }) {
    return ContentFilterState(
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      educationalLevelId:
          clearEducationalLevelId ? null : (educationalLevelId ?? this.educationalLevelId),
      topicId: clearTopicId ? null : (topicId ?? this.topicId),
      contentType: clearContentType ? null : (contentType ?? this.contentType),
      difficultyLevel:
          clearDifficultyLevel ? null : (difficultyLevel ?? this.difficultyLevel),
      status: clearStatus ? null : (status ?? this.status),
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
    );
  }

  @override
  List<Object?> get props => [
        subjectId,
        educationalLevelId,
        topicId,
        contentType,
        difficultyLevel,
        status,
        searchTerm,
      ];
}

// ─── State ──────────────────────────────────────────────────────────────────

class ContentState extends Equatable {
  final List<ContentItem> contentItems;
  final ContentItem? selectedContent;
  final List<ContentVersion> versions;
  final CcmsStats? stats;
  final ContentFilterState filters;
  final bool isLoading;
  final String? error;

  const ContentState({
    this.contentItems = const [],
    this.selectedContent,
    this.versions = const [],
    this.stats,
    this.filters = const ContentFilterState(),
    this.isLoading = false,
    this.error,
  });

  ContentState copyWith({
    List<ContentItem>? contentItems,
    ContentItem? selectedContent,
    List<ContentVersion>? versions,
    CcmsStats? stats,
    ContentFilterState? filters,
    bool? isLoading,
    String? error,
  }) {
    return ContentState(
      contentItems: contentItems ?? this.contentItems,
      selectedContent: selectedContent ?? this.selectedContent,
      versions: versions ?? this.versions,
      stats: stats ?? this.stats,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        contentItems,
        selectedContent,
        versions,
        stats,
        filters,
        isLoading,
        error,
      ];
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class ContentNotifier extends StateNotifier<ContentState> {
  final GetContentItemsUseCase _getContentItemsUseCase;
  final GetContentByIdUseCase _getContentByIdUseCase;
  final CreateContentUseCase _createContentUseCase;
  final UpdateContentUseCase _updateContentUseCase;
  final DeleteContentUseCase _deleteContentUseCase;
  final PublishContentUseCase _publishContentUseCase;
  final ArchiveContentUseCase _archiveContentUseCase;
  final GetContentVersionsUseCase _getContentVersionsUseCase;
  final GetCcmsStatsUseCase _getCcmsStatsUseCase;

  ContentNotifier({
    required GetContentItemsUseCase getContentItemsUseCase,
    required GetContentByIdUseCase getContentByIdUseCase,
    required CreateContentUseCase createContentUseCase,
    required UpdateContentUseCase updateContentUseCase,
    required DeleteContentUseCase deleteContentUseCase,
    required PublishContentUseCase publishContentUseCase,
    required ArchiveContentUseCase archiveContentUseCase,
    required GetContentVersionsUseCase getContentVersionsUseCase,
    required GetCcmsStatsUseCase getCcmsStatsUseCase,
  })  : _getContentItemsUseCase = getContentItemsUseCase,
        _getContentByIdUseCase = getContentByIdUseCase,
        _createContentUseCase = createContentUseCase,
        _updateContentUseCase = updateContentUseCase,
        _deleteContentUseCase = deleteContentUseCase,
        _publishContentUseCase = publishContentUseCase,
        _archiveContentUseCase = archiveContentUseCase,
        _getContentVersionsUseCase = getContentVersionsUseCase,
        _getCcmsStatsUseCase = getCcmsStatsUseCase,
        super(const ContentState());

  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, statusCode, data) => 'Server error: $message',
      cache: (message) => 'Cache error: $message',
      auth: (message, code) => 'Auth error: $message',
      network: (message) => 'Network error: $message',
      validation: (message, fieldErrors) => 'Validation error: $message',
      notFound: (message) => 'Not found: $message',
      unauthorized: (message) => 'Unauthorized: $message',
      forbidden: (message) => 'Forbidden: $message',
    );
  }

  Future<void> loadContentItems([ContentFilterState? filters]) async {
    state = state.copyWith(isLoading: true, error: null);
    final f = filters ?? state.filters;
    final result = await _getContentItemsUseCase(GetContentItemsParams(
      subjectId: f.subjectId,
      educationalLevelId: f.educationalLevelId,
      topicId: f.topicId,
      contentType: f.contentType,
      difficultyLevel: f.difficultyLevel,
      status: f.status,
      search: f.searchTerm,
    ));
    result.fold(
      onSuccess: (items) => state = state.copyWith(
        contentItems: items,
        filters: f,
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadContentById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContentByIdUseCase(GetContentByIdParams(id: id));
    result.fold(
      onSuccess: (content) => state = state.copyWith(
        selectedContent: content,
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> createContent(ContentItem data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createContentUseCase(
      CreateContentParams(content: data),
    );
    result.fold(
      onSuccess: (created) => state = state.copyWith(
        contentItems: [...state.contentItems, created],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> updateContent(String id, ContentItem data) async {
    state = state.copyWith(isLoading: true, error: null);
    final updatedData = data.copyWith(id: id);
    final result = await _updateContentUseCase(
      UpdateContentParams(content: updatedData),
    );
    result.fold(
      onSuccess: (updated) {
        final list = state.contentItems
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        state = state.copyWith(
          contentItems: list,
          selectedContent: updated,
          isLoading: false,
        );
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> deleteContent(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _deleteContentUseCase(DeleteContentParams(id: id));
    result.fold(
      onSuccess: (_) => state = state.copyWith(
        contentItems: state.contentItems.where((c) => c.id != id).toList(),
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> publishContent(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _publishContentUseCase(PublishContentParams(id: id));
    result.fold(
      onSuccess: (updated) {
        final list = state.contentItems
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        state = state.copyWith(contentItems: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> archiveContent(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _archiveContentUseCase(ArchiveContentParams(id: id));
    result.fold(
      onSuccess: (updated) {
        final list = state.contentItems
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        state = state.copyWith(contentItems: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadVersions(String contentItemId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContentVersionsUseCase(
      GetContentVersionsParams(contentItemId: contentItemId),
    );
    result.fold(
      onSuccess: (versions) =>
          state = state.copyWith(versions: versions, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadStats(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCcmsStatsUseCase(
      GetCcmsStatsParams(schoolId: schoolId),
    );
    result.fold(
      onSuccess: (stats) =>
          state = state.copyWith(stats: stats, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  void setFilters(ContentFilterState filters) {
    state = state.copyWith(filters: filters);
  }

  void clearFilters() {
    state = state.copyWith(filters: const ContentFilterState());
  }
}
