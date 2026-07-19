import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── CreateImportUseCase ────────────────────────────────────────────

class CreateImportParams extends Equatable {
  final ContentImport importEntry;

  const CreateImportParams({required this.importEntry});

  @override
  List<Object?> get props => [importEntry];
}

class CreateImportUseCase {
  final CcmsRepository _repository;
  CreateImportUseCase(this._repository);

  Future<Result<ContentImport>> call(CreateImportParams params) async {
    return await _repository.createImport(params.importEntry);
  }
}

// ─── GetImportsUseCase ──────────────────────────────────────────────

class GetImportsParams extends Equatable {
  final String? schoolId;
  final ImportStatus? status;
  final int limit;
  final int offset;

  const GetImportsParams({
    this.schoolId,
    this.status,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [schoolId, status, limit, offset];
}

class GetImportsUseCase {
  final CcmsRepository _repository;
  GetImportsUseCase(this._repository);

  Future<Result<List<ContentImport>>> call(GetImportsParams params) async {
    return await _repository.getImports(
      schoolId: params.schoolId,
      status: params.status,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

// ─── GetImportByIdUseCase ───────────────────────────────────────────

class GetImportByIdParams extends Equatable {
  final String id;

  const GetImportByIdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

class GetImportByIdUseCase {
  final CcmsRepository _repository;
  GetImportByIdUseCase(this._repository);

  Future<Result<ContentImport>> call(GetImportByIdParams params) async {
    return await _repository.getImportById(params.id);
  }
}
