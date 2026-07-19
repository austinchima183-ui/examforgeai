import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetCollectionsUseCase ──────────────────────────────────────────

class GetCollectionsParams extends Equatable {
  final String? subjectId;
  final String? educationalLevelId;
  final String? schoolId;
  final bool? isPublic;
  final int limit;
  final int offset;

  const GetCollectionsParams({
    this.subjectId,
    this.educationalLevelId,
    this.schoolId,
    this.isPublic,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [subjectId, educationalLevelId, schoolId, isPublic, limit, offset];
}

class GetCollectionsUseCase {
  final CcmsRepository _repository;
  GetCollectionsUseCase(this._repository);

  Future<Result<List<ContentCollection>>> call(
    GetCollectionsParams params,
  ) async {
    return await _repository.getCollections(
      subjectId: params.subjectId,
      educationalLevelId: params.educationalLevelId,
      schoolId: params.schoolId,
      isPublic: params.isPublic,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── CreateCollectionUseCase ────────────────────────────────────────

class CreateCollectionParams extends Equatable {
  final ContentCollection collection;

  const CreateCollectionParams({required this.collection});

  @override
  List<Object?> get props => [collection];
}

class CreateCollectionUseCase {
  final CcmsRepository _repository;
  CreateCollectionUseCase(this._repository);

  Future<Result<ContentCollection>> call(
    CreateCollectionParams params,
  ) async {
    return await _repository.createCollection(params.collection);
  }
}

// ─── UpdateCollectionUseCase ────────────────────────────────────────

class UpdateCollectionParams extends Equatable {
  final ContentCollection collection;

  const UpdateCollectionParams({required this.collection});

  @override
  List<Object?> get props => [collection];
}

class UpdateCollectionUseCase {
  final CcmsRepository _repository;
  UpdateCollectionUseCase(this._repository);

  Future<Result<ContentCollection>> call(
    UpdateCollectionParams params,
  ) async {
    return await _repository.updateCollection(params.collection);
  }
}

// ─── DeleteCollectionUseCase ────────────────────────────────────────

class DeleteCollectionParams extends Equatable {
  final String id;

  const DeleteCollectionParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteCollectionUseCase {
  final CcmsRepository _repository;
  DeleteCollectionUseCase(this._repository);

  Future<Result<bool>> call(DeleteCollectionParams params) async {
    return await _repository.deleteCollection(params.id);
  }
}

// ─── AddCollectionItemUseCase ───────────────────────────────────────

class AddCollectionItemParams extends Equatable {
  final ContentCollectionItem item;

  const AddCollectionItemParams({required this.item});

  @override
  List<Object?> get props => [item];
}

class AddCollectionItemUseCase {
  final CcmsRepository _repository;
  AddCollectionItemUseCase(this._repository);

  Future<Result<ContentCollectionItem>> call(
    AddCollectionItemParams params,
  ) async {
    return await _repository.addCollectionItem(params.item);
  }
}

// ─── RemoveCollectionItemUseCase ────────────────────────────────────

class RemoveCollectionItemParams extends Equatable {
  final String collectionItemId;

  const RemoveCollectionItemParams({required this.collectionItemId});

  @override
  List<Object?> get props => [collectionItemId];
}

class RemoveCollectionItemUseCase {
  final CcmsRepository _repository;
  RemoveCollectionItemUseCase(this._repository);

  Future<Result<bool>> call(RemoveCollectionItemParams params) async {
    return await _repository.removeCollectionItem(params.collectionItemId);
  }
}
