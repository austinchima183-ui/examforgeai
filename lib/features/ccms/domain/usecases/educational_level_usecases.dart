import 'package:equatable/equatable.dart';
import '../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetEducationalLevelsUseCase ─────────────────────────────────────

class GetEducationalLevelsUseCase {
  final CcmsRepository _repository;
  GetEducationalLevelsUseCase(this._repository);

  Future<Result<List<EducationalLevel>>> call() async {
    return await _repository.getEducationalLevels();
  }
}

// ─── GetSchoolLevelsUseCase ─────────────────────────────────────────

class GetSchoolLevelsParams extends Equatable {
  final String schoolId;

  const GetSchoolLevelsParams({required this.schoolId});

  @override
  List<Object?> get props => [schoolId];
}

class GetSchoolLevelsUseCase {
  final CcmsRepository _repository;
  GetSchoolLevelsUseCase(this._repository);

  Future<Result<List<SchoolLevelConfiguration>>> call(
    GetSchoolLevelsParams params,
  ) async {
    return await _repository.getSchoolLevels(params.schoolId);
  }
}

// ─── ConfigureSchoolLevelUseCase ────────────────────────────────────

class ConfigureSchoolLevelParams extends Equatable {
  final SchoolLevelConfiguration configuration;

  const ConfigureSchoolLevelParams({required this.configuration});

  @override
  List<Object?> get props => [configuration];
}

class ConfigureSchoolLevelUseCase {
  final CcmsRepository _repository;
  ConfigureSchoolLevelUseCase(this._repository);

  Future<Result<SchoolLevelConfiguration>> call(
    ConfigureSchoolLevelParams params,
  ) async {
    return await _repository.configureSchoolLevel(params.configuration);
  }
}

// ─── UpdateSchoolLevelConfigurationUseCase ──────────────────────────

class UpdateSchoolLevelConfigurationParams extends Equatable {
  final SchoolLevelConfiguration configuration;

  const UpdateSchoolLevelConfigurationParams({required this.configuration});

  @override
  List<Object?> get props => [configuration];
}

class UpdateSchoolLevelConfigurationUseCase {
  final CcmsRepository _repository;
  UpdateSchoolLevelConfigurationUseCase(this._repository);

  Future<Result<SchoolLevelConfiguration>> call(
    UpdateSchoolLevelConfigurationParams params,
  ) async {
    return await _repository.updateSchoolLevelConfiguration(
      params.configuration,
    );
  }
}
