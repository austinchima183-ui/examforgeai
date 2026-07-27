import 'package:equatable/equatable.dart';
import '../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetContentItemsUseCase ─────────────────────────────────────────

class GetContentItemsParams extends Equatable {
  final String? subjectId;
  final String? educationalLevelId;
  final String? topicId;
  final String? subtopicId;
  final String? curriculumId;
  final String? schoolId;
  final ContentType? contentType;
  final QuestionCategory? questionCategory;
  final DifficultyLevel? difficultyLevel;
  final BloomTaxonomy? bloomLevel;
  final ContentStatus? status;
  final bool? isPastQuestion;
  final bool? isAiGenerated;
  final String? search;
  final int limit;
  final int offset;

  const GetContentItemsParams({
    this.subjectId,
    this.educationalLevelId,
    this.topicId,
    this.subtopicId,
    this.curriculumId,
    this.schoolId,
    this.contentType,
    this.questionCategory,
    this.difficultyLevel,
    this.bloomLevel,
    this.status,
    this.isPastQuestion,
    this.isAiGenerated,
    this.search,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [
        subjectId,
        educationalLevelId,
        topicId,
        subtopicId,
        curriculumId,
        schoolId,
        contentType,
        questionCategory,
        difficultyLevel,
        bloomLevel,
        status,
        isPastQuestion,
        isAiGenerated,
        search,
        limit,
        offset,
      ];
}

class GetContentItemsUseCase {
  final CcmsRepository _repository;
  GetContentItemsUseCase(this._repository);

  Future<Result<List<ContentItem>>> call(GetContentItemsParams params) async {
    return await _repository.getContentItems(
      subjectId: params.subjectId,
      educationalLevelId: params.educationalLevelId,
      topicId: params.topicId,
      subtopicId: params.subtopicId,
      curriculumId: params.curriculumId,
      schoolId: params.schoolId,
      contentType: params.contentType,
      questionCategory: params.questionCategory,
      difficultyLevel: params.difficultyLevel,
      bloomLevel: params.bloomLevel,
      status: params.status,
      isPastQuestion: params.isPastQuestion,
      isAiGenerated: params.isAiGenerated,
      search: params.search,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── GetContentByIdUseCase ──────────────────────────────────────────

class GetContentByIdParams extends Equatable {
  final String id;

  const GetContentByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class GetContentByIdUseCase {
  final CcmsRepository _repository;
  GetContentByIdUseCase(this._repository);

  Future<Result<ContentItem>> call(GetContentByIdParams params) async {
    return await _repository.getContentById(params.id);
  }
}

// ─── CreateContentUseCase ───────────────────────────────────────────

class CreateContentParams extends Equatable {
  final ContentItem content;

  const CreateContentParams({required this.content});

  @override
  List<Object?> get props => [content];
}

class CreateContentUseCase {
  final CcmsRepository _repository;
  CreateContentUseCase(this._repository);

  Future<Result<ContentItem>> call(CreateContentParams params) async {
    return await _repository.createContent(params.content);
  }
}

// ─── UpdateContentUseCase ───────────────────────────────────────────

class UpdateContentParams extends Equatable {
  final ContentItem content;

  const UpdateContentParams({required this.content});

  @override
  List<Object?> get props => [content];
}

class UpdateContentUseCase {
  final CcmsRepository _repository;
  UpdateContentUseCase(this._repository);

  Future<Result<ContentItem>> call(UpdateContentParams params) async {
    return await _repository.updateContent(params.content);
  }
}

// ─── DeleteContentUseCase ───────────────────────────────────────────

class DeleteContentParams extends Equatable {
  final String id;

  const DeleteContentParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteContentUseCase {
  final CcmsRepository _repository;
  DeleteContentUseCase(this._repository);

  Future<Result<bool>> call(DeleteContentParams params) async {
    return await _repository.deleteContent(params.id);
  }
}

// ─── PublishContentUseCase ──────────────────────────────────────────

class PublishContentParams extends Equatable {
  final String id;

  const PublishContentParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class PublishContentUseCase {
  final CcmsRepository _repository;
  PublishContentUseCase(this._repository);

  Future<Result<ContentItem>> call(PublishContentParams params) async {
    return await _repository.publishContent(params.id);
  }
}

// ─── ArchiveContentUseCase ──────────────────────────────────────────

class ArchiveContentParams extends Equatable {
  final String id;

  const ArchiveContentParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class ArchiveContentUseCase {
  final CcmsRepository _repository;
  ArchiveContentUseCase(this._repository);

  Future<Result<ContentItem>> call(ArchiveContentParams params) async {
    return await _repository.archiveContent(params.id);
  }
}

// ─── GetContentVersionsUseCase ──────────────────────────────────────

class GetContentVersionsParams extends Equatable {
  final String contentItemId;

  const GetContentVersionsParams({required this.contentItemId});

  @override
  List<Object?> get props => [contentItemId];
}

class GetContentVersionsUseCase {
  final CcmsRepository _repository;
  GetContentVersionsUseCase(this._repository);

  Future<Result<List<ContentVersion>>> call(
    GetContentVersionsParams params,
  ) async {
    return await _repository.getContentVersions(params.contentItemId);
  }
}

// ─── GetContentWithDetailsUseCase ───────────────────────────────────

class GetContentWithDetailsParams extends Equatable {
  final String id;

  const GetContentWithDetailsParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class GetContentWithDetailsUseCase {
  final CcmsRepository _repository;
  GetContentWithDetailsUseCase(this._repository);

  Future<Result<ContentItem>> call(GetContentWithDetailsParams params) async {
    return await _repository.getContentWithDetails(params.id);
  }
}
