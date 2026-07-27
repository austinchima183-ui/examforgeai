import 'package:equatable/equatable.dart';
import '../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetTopicsUseCase ───────────────────────────────────────────────

class GetTopicsParams extends Equatable {
  final String? subjectId;
  final String? educationalLevelId;
  final String? curriculumId;
  final String? parentTopicId;

  const GetTopicsParams({
    this.subjectId,
    this.educationalLevelId,
    this.curriculumId,
    this.parentTopicId,
  });

  @override
  List<Object?> get props => [subjectId, educationalLevelId, curriculumId, parentTopicId];
}

class GetTopicsUseCase {
  final CcmsRepository _repository;
  GetTopicsUseCase(this._repository);

  Future<Result<List<Topic>>> call(GetTopicsParams params) async {
    return await _repository.getTopics(
      subjectId: params.subjectId,
      educationalLevelId: params.educationalLevelId,
      curriculumId: params.curriculumId,
      parentTopicId: params.parentTopicId,
    );
  }
}

// ─── CreateTopicUseCase ─────────────────────────────────────────────

class CreateTopicParams extends Equatable {
  final Topic topic;

  const CreateTopicParams({required this.topic});

  @override
  List<Object?> get props => [topic];
}

class CreateTopicUseCase {
  final CcmsRepository _repository;
  CreateTopicUseCase(this._repository);

  Future<Result<Topic>> call(CreateTopicParams params) async {
    return await _repository.createTopic(params.topic);
  }
}

// ─── UpdateTopicUseCase ─────────────────────────────────────────────

class UpdateTopicParams extends Equatable {
  final Topic topic;

  const UpdateTopicParams({required this.topic});

  @override
  List<Object?> get props => [topic];
}

class UpdateTopicUseCase {
  final CcmsRepository _repository;
  UpdateTopicUseCase(this._repository);

  Future<Result<Topic>> call(UpdateTopicParams params) async {
    return await _repository.updateTopic(params.topic);
  }
}

// ─── DeleteTopicUseCase ─────────────────────────────────────────────

class DeleteTopicParams extends Equatable {
  final String id;

  const DeleteTopicParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteTopicUseCase {
  final CcmsRepository _repository;
  DeleteTopicUseCase(this._repository);

  Future<Result<bool>> call(DeleteTopicParams params) async {
    return await _repository.deleteTopic(params.id);
  }
}

// ─── GetSubtopicsUseCase ────────────────────────────────────────────

class GetSubtopicsParams extends Equatable {
  final String topicId;

  const GetSubtopicsParams({required this.topicId});

  @override
  List<Object?> get props => [topicId];
}

class GetSubtopicsUseCase {
  final CcmsRepository _repository;
  GetSubtopicsUseCase(this._repository);

  Future<Result<List<Subtopic>>> call(GetSubtopicsParams params) async {
    return await _repository.getSubtopics(params.topicId);
  }
}

// ─── CreateSubtopicUseCase ──────────────────────────────────────────

class CreateSubtopicParams extends Equatable {
  final Subtopic subtopic;

  const CreateSubtopicParams({required this.subtopic});

  @override
  List<Object?> get props => [subtopic];
}

class CreateSubtopicUseCase {
  final CcmsRepository _repository;
  CreateSubtopicUseCase(this._repository);

  Future<Result<Subtopic>> call(CreateSubtopicParams params) async {
    return await _repository.createSubtopic(params.subtopic);
  }
}

// ─── UpdateSubtopicUseCase ──────────────────────────────────────────

class UpdateSubtopicParams extends Equatable {
  final Subtopic subtopic;

  const UpdateSubtopicParams({required this.subtopic});

  @override
  List<Object?> get props => [subtopic];
}

class UpdateSubtopicUseCase {
  final CcmsRepository _repository;
  UpdateSubtopicUseCase(this._repository);

  Future<Result<Subtopic>> call(UpdateSubtopicParams params) async {
    return await _repository.updateSubtopic(params.subtopic);
  }
}

// ─── DeleteSubtopicUseCase ──────────────────────────────────────────

class DeleteSubtopicParams extends Equatable {
  final String id;

  const DeleteSubtopicParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteSubtopicUseCase {
  final CcmsRepository _repository;
  DeleteSubtopicUseCase(this._repository);

  Future<Result<bool>> call(DeleteSubtopicParams params) async {
    return await _repository.deleteSubtopic(params.id);
  }
}

// ─── GetCurriculumTreeUseCase ───────────────────────────────────────

class GetCurriculumTreeParams extends Equatable {
  final String subjectId;

  const GetCurriculumTreeParams({required this.subjectId});

  @override
  List<Object?> get props => [subjectId];
}

class GetCurriculumTreeUseCase {
  final CcmsRepository _repository;
  GetCurriculumTreeUseCase(this._repository);

  Future<Result<List<Topic>>> call(GetCurriculumTreeParams params) async {
    return await _repository.getCurriculumTree(params.subjectId);
  }
}
