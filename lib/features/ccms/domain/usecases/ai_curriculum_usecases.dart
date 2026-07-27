import 'package:equatable/equatable.dart';
import '../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetAiCurriculumConfigUseCase ───────────────────────────────────

class GetAiCurriculumConfigParams extends Equatable {
  final String schoolId;
  final String subjectId;
  final String educationalLevelId;

  const GetAiCurriculumConfigParams({
    required this.schoolId,
    required this.subjectId,
    required this.educationalLevelId,
  });

  @override
  List<Object?> get props => [schoolId, subjectId, educationalLevelId];
}

class GetAiCurriculumConfigUseCase {
  final CcmsRepository _repository;
  GetAiCurriculumConfigUseCase(this._repository);

  Future<Result<AiCurriculumConfig>> call(
    GetAiCurriculumConfigParams params,
  ) async {
    return await _repository.getAiCurriculumConfig(
      schoolId: params.schoolId,
      subjectId: params.subjectId,
      educationalLevelId: params.educationalLevelId,
    );
  }
}

// ─── UpsertAiCurriculumConfigUseCase ────────────────────────────────

class UpsertAiCurriculumConfigParams extends Equatable {
  final AiCurriculumConfig config;

  const UpsertAiCurriculumConfigParams({required this.config});

  @override
  List<Object?> get props => [config];
}

class UpsertAiCurriculumConfigUseCase {
  final CcmsRepository _repository;
  UpsertAiCurriculumConfigUseCase(this._repository);

  Future<Result<AiCurriculumConfig>> call(
    UpsertAiCurriculumConfigParams params,
  ) async {
    return await _repository.upsertAiCurriculumConfig(params.config);
  }
}

// ─── GetAiGenerationRulesUseCase ────────────────────────────────────

class GetAiGenerationRulesParams extends Equatable {
  final String? educationalLevelId;
  final String? subjectId;
  final bool? isActive;

  const GetAiGenerationRulesParams({
    this.educationalLevelId,
    this.subjectId,
    this.isActive,
  });

  @override
  List<Object?> get props => [educationalLevelId, subjectId, isActive];
}

class GetAiGenerationRulesUseCase {
  final CcmsRepository _repository;
  GetAiGenerationRulesUseCase(this._repository);

  Future<Result<List<AiGenerationRule>>> call(
    GetAiGenerationRulesParams params,
  ) async {
    return await _repository.getAiGenerationRules(
      educationalLevelId: params.educationalLevelId,
      subjectId: params.subjectId,
      isActive: params.isActive,
    );
  }
}

// ─── CreateAiGenerationRuleUseCase ──────────────────────────────────

class CreateAiGenerationRuleParams extends Equatable {
  final AiGenerationRule rule;

  const CreateAiGenerationRuleParams({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class CreateAiGenerationRuleUseCase {
  final CcmsRepository _repository;
  CreateAiGenerationRuleUseCase(this._repository);

  Future<Result<AiGenerationRule>> call(
    CreateAiGenerationRuleParams params,
  ) async {
    return await _repository.createAiGenerationRule(params.rule);
  }
}

// ─── UpdateAiGenerationRuleUseCase ──────────────────────────────────

class UpdateAiGenerationRuleParams extends Equatable {
  final AiGenerationRule rule;

  const UpdateAiGenerationRuleParams({required this.rule});

  @override
  List<Object?> get props => [rule];
}

class UpdateAiGenerationRuleUseCase {
  final CcmsRepository _repository;
  UpdateAiGenerationRuleUseCase(this._repository);

  Future<Result<AiGenerationRule>> call(
    UpdateAiGenerationRuleParams params,
  ) async {
    return await _repository.updateAiGenerationRule(params.rule);
  }
}
