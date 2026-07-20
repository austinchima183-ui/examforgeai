import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetSubjectsUseCase ─────────────────────────────────────────────

class GetSubjectsParams extends Equatable {
  final String? schoolId;
  final String? educationalLevelId;
  final String? curriculumId;

  const GetSubjectsParams({
    this.schoolId,
    this.educationalLevelId,
    this.curriculumId,
  });

  @override
  List<Object?> get props => [schoolId, educationalLevelId, curriculumId];
}

class GetSubjectsUseCase {
  final CcmsRepository _repository;
  GetSubjectsUseCase(this._repository);

  Future<Result<List<Subject>>> call(GetSubjectsParams params) async {
    return await _repository.getSubjects(
      schoolId: params.schoolId,
      educationalLevelId: params.educationalLevelId,
      curriculumId: params.curriculumId,
    );
  }
}

// ─── GetSubjectByIdUseCase ──────────────────────────────────────────

class GetSubjectByIdParams extends Equatable {
  final String id;

  const GetSubjectByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class GetSubjectByIdUseCase {
  final CcmsRepository _repository;
  GetSubjectByIdUseCase(this._repository);

  Future<Result<Subject>> call(GetSubjectByIdParams params) async {
    return await _repository.getSubjectById(params.id);
  }
}

// ─── CreateSubjectUseCase ───────────────────────────────────────────

class CreateSubjectParams extends Equatable {
  final Subject subject;

  const CreateSubjectParams({required this.subject});

  @override
  List<Object?> get props => [subject];
}

class CreateSubjectUseCase {
  final CcmsRepository _repository;
  CreateSubjectUseCase(this._repository);

  Future<Result<Subject>> call(CreateSubjectParams params) async {
    return await _repository.createSubject(params.subject);
  }
}

// ─── UpdateSubjectUseCase ───────────────────────────────────────────

class UpdateSubjectParams extends Equatable {
  final Subject subject;

  const UpdateSubjectParams({required this.subject});

  @override
  List<Object?> get props => [subject];
}

class UpdateSubjectUseCase {
  final CcmsRepository _repository;
  UpdateSubjectUseCase(this._repository);

  Future<Result<Subject>> call(UpdateSubjectParams params) async {
    return await _repository.updateSubject(params.subject);
  }
}

// ─── DeleteSubjectUseCase ───────────────────────────────────────────

class DeleteSubjectParams extends Equatable {
  final String id;

  const DeleteSubjectParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class DeleteSubjectUseCase {
  final CcmsRepository _repository;
  DeleteSubjectUseCase(this._repository);

  Future<Result<bool>> call(DeleteSubjectParams params) async {
    return await _repository.deleteSubject(params.id);
  }
}

// ─── GetLevelSubjectsUseCase ────────────────────────────────────────

class GetLevelSubjectsParams extends Equatable {
  final String educationalLevelId;

  const GetLevelSubjectsParams({required this.educationalLevelId});

  @override
  List<Object?> get props => [educationalLevelId];
}

class GetLevelSubjectsUseCase {
  final CcmsRepository _repository;
  GetLevelSubjectsUseCase(this._repository);

  Future<Result<List<Subject>>> call(GetLevelSubjectsParams params) async {
    return await _repository.getLevelSubjects(params.educationalLevelId);
  }
}
