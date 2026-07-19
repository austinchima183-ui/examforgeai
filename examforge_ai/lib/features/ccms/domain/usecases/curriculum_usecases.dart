import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetCurriculaUseCase ────────────────────────────────────────────

class GetCurriculaParams extends Equatable {
  final String? countryCode;
  final CurriculumType? curriculumType;
  final bool? isActive;

  const GetCurriculaParams({
    this.countryCode,
    this.curriculumType,
    this.isActive,
  });

  @override
  List<Object?> get props => [countryCode, curriculumType, isActive];
}

class GetCurriculaUseCase {
  final CcmsRepository _repository;
  GetCurriculaUseCase(this._repository);

  Future<Result<List<Curriculum>>> call(GetCurriculaParams params) async {
    return await _repository.getCurricula(
      countryCode: params.countryCode,
      curriculumType: params.curriculumType,
      isActive: params.isActive,
    );
  }
}

// ─── GetCurriculumByIdUseCase ───────────────────────────────────────

class GetCurriculumByIdParams extends Equatable {
  final String id;

  const GetCurriculumByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class GetCurriculumByIdUseCase {
  final CcmsRepository _repository;
  GetCurriculumByIdUseCase(this._repository);

  Future<Result<Curriculum>> call(GetCurriculumByIdParams params) async {
    return await _repository.getCurriculumById(params.id);
  }
}

// ─── CreateCurriculumUseCase ────────────────────────────────────────

class CreateCurriculumParams extends Equatable {
  final Curriculum curriculum;

  const CreateCurriculumParams({required this.curriculum});

  @override
  List<Object?> get props => [curriculum];
}

class CreateCurriculumUseCase {
  final CcmsRepository _repository;
  CreateCurriculumUseCase(this._repository);

  Future<Result<Curriculum>> call(CreateCurriculumParams params) async {
    return await _repository.createCurriculum(params.curriculum);
  }
}

// ─── UpdateCurriculumUseCase ────────────────────────────────────────

class UpdateCurriculumParams extends Equatable {
  final Curriculum curriculum;

  const UpdateCurriculumParams({required this.curriculum});

  @override
  List<Object?> get props => [curriculum];
}

class UpdateCurriculumUseCase {
  final CcmsRepository _repository;
  UpdateCurriculumUseCase(this._repository);

  Future<Result<Curriculum>> call(UpdateCurriculumParams params) async {
    return await _repository.updateCurriculum(params.curriculum);
  }
}

// ─── GetCurriculumVersionsUseCase ───────────────────────────────────

class GetCurriculumVersionsParams extends Equatable {
  final String curriculumId;

  const GetCurriculumVersionsParams({required this.curriculumId});

  @override
  List<Object?> get props => [curriculumId];
}

class GetCurriculumVersionsUseCase {
  final CcmsRepository _repository;
  GetCurriculumVersionsUseCase(this._repository);

  Future<Result<List<CurriculumVersion>>> call(
    GetCurriculumVersionsParams params,
  ) async {
    return await _repository.getCurriculumVersions(params.curriculumId);
  }
}

// ─── GetCurriculumLevelMappingsUseCase ──────────────────────────────

class GetCurriculumLevelMappingsParams extends Equatable {
  final String curriculumId;

  const GetCurriculumLevelMappingsParams({required this.curriculumId});

  @override
  List<Object?> get props => [curriculumId];
}

class GetCurriculumLevelMappingsUseCase {
  final CcmsRepository _repository;
  GetCurriculumLevelMappingsUseCase(this._repository);

  Future<Result<List<CurriculumLevelMapping>>> call(
    GetCurriculumLevelMappingsParams params,
  ) async {
    return await _repository.getCurriculumLevelMappings(params.curriculumId);
  }
}
