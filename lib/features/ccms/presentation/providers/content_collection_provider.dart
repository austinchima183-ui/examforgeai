import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/content_collection_usecases.dart';

class ContentCollectionState extends Equatable {
  final List<ContentCollection> collections;
  final ContentCollection? selectedCollection;
  final bool isLoading;
  final String? error;

  const ContentCollectionState({this.collections = const [], this.selectedCollection, this.isLoading = false, this.error});

  ContentCollectionState copyWith({List<ContentCollection>? collections, ContentCollection? selectedCollection, bool? isLoading, String? error}) {
    return ContentCollectionState(collections: collections ?? this.collections, selectedCollection: selectedCollection ?? this.selectedCollection, isLoading: isLoading ?? this.isLoading, error: error);
  }

  @override
  List<Object?> get props => [collections, selectedCollection, isLoading, error];
}

class ContentCollectionNotifier extends StateNotifier<ContentCollectionState> {
  final GetCollectionsUseCase _getCollectionsUseCase;
  final CreateCollectionUseCase _createCollectionUseCase;
  final UpdateCollectionUseCase _updateCollectionUseCase;
  final DeleteCollectionUseCase _deleteCollectionUseCase;
  final AddCollectionItemUseCase _addCollectionItemUseCase;
  final RemoveCollectionItemUseCase _removeCollectionItemUseCase;

  ContentCollectionNotifier({
    required GetCollectionsUseCase getCollectionsUseCase,
    required CreateCollectionUseCase createCollectionUseCase,
    required UpdateCollectionUseCase updateCollectionUseCase,
    required DeleteCollectionUseCase deleteCollectionUseCase,
    required AddCollectionItemUseCase addCollectionItemUseCase,
    required RemoveCollectionItemUseCase removeCollectionItemUseCase,
  })  : _getCollectionsUseCase = getCollectionsUseCase,
        _createCollectionUseCase = createCollectionUseCase,
        _updateCollectionUseCase = updateCollectionUseCase,
        _deleteCollectionUseCase = deleteCollectionUseCase,
        _addCollectionItemUseCase = addCollectionItemUseCase,
        _removeCollectionItemUseCase = removeCollectionItemUseCase,
        super(const ContentCollectionState());

  Future<void> loadCollections({String? subjectId, String? educationalLevelId, String? schoolId}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCollectionsUseCase(GetCollectionsParams(subjectId: subjectId, educationalLevelId: educationalLevelId, schoolId: schoolId));
    result.fold(
      onSuccess: (collections) => state = state.copyWith(collections: collections, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> createCollection(ContentCollection collection) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createCollectionUseCase(CreateCollectionParams(collection: collection));
    result.fold(
      onSuccess: (created) => state = state.copyWith(collections: [...state.collections, created], isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> updateCollection(ContentCollection collection) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateCollectionUseCase(UpdateCollectionParams(collection: collection));
    result.fold(
      onSuccess: (updated) {
        final list = state.collections.map((c) => c.id == updated.id ? updated : c).toList();
        state = state.copyWith(collections: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> deleteCollection(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _deleteCollectionUseCase(DeleteCollectionParams(id: id));
    result.fold(
      onSuccess: (_) => state = state.copyWith(collections: state.collections.where((c) => c.id != id).toList(), isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> addCollectionItem(ContentCollectionItem item) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _addCollectionItemUseCase(AddCollectionItemParams(item: item));
    result.fold(
      onSuccess: (_) => state = state.copyWith(isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> removeCollectionItem(String collectionItemId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _removeCollectionItemUseCase(RemoveCollectionItemParams(collectionItemId: collectionItemId));
    result.fold(
      onSuccess: (_) => state = state.copyWith(isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }
}

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
