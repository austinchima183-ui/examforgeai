import 'package:equatable/equatable.dart';
import '../../../../../core/utils/result.dart';
import '../entities/ccms_entities.dart';
import '../repositories/ccms_repository.dart';

// ─── GetAnswerEntryUseCase ──────────────────────────────────────────

class GetAnswerEntryParams extends Equatable {
  final String contentItemId;

  const GetAnswerEntryParams({required this.contentItemId});

  @override
  List<Object?> get props => [contentItemId];
}

class GetAnswerEntryUseCase {
  final CcmsRepository _repository;
  GetAnswerEntryUseCase(this._repository);

  Future<Result<AnswerRepositoryEntry>> call(
    GetAnswerEntryParams params,
  ) async {
    return await _repository.getAnswerRepositoryEntry(params.contentItemId);
  }
}

// ─── CreateAnswerEntryUseCase ───────────────────────────────────────

class CreateAnswerEntryParams extends Equatable {
  final AnswerRepositoryEntry entry;

  const CreateAnswerEntryParams({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class CreateAnswerEntryUseCase {
  final CcmsRepository _repository;
  CreateAnswerEntryUseCase(this._repository);

  Future<Result<AnswerRepositoryEntry>> call(
    CreateAnswerEntryParams params,
  ) async {
    return await _repository.createAnswerEntry(params.entry);
  }
}

// ─── UpdateAnswerEntryUseCase ───────────────────────────────────────

class UpdateAnswerEntryParams extends Equatable {
  final AnswerRepositoryEntry entry;

  const UpdateAnswerEntryParams({required this.entry});

  @override
  List<Object?> get props => [entry];
}

class UpdateAnswerEntryUseCase {
  final CcmsRepository _repository;
  UpdateAnswerEntryUseCase(this._repository);

  Future<Result<AnswerRepositoryEntry>> call(
    UpdateAnswerEntryParams params,
  ) async {
    return await _repository.updateAnswerEntry(params.entry);
  }
}

// ─── VerifyAnswerUseCase ────────────────────────────────────────────

class VerifyAnswerParams extends Equatable {
  final String entryId;
  final String verifiedBy;

  const VerifyAnswerParams({
    required this.entryId,
    required this.verifiedBy,
  });

  @override
  List<Object?> get props => [entryId, verifiedBy];
}

class VerifyAnswerUseCase {
  final CcmsRepository _repository;
  VerifyAnswerUseCase(this._repository);

  Future<Result<AnswerRepositoryEntry>> call(
    VerifyAnswerParams params,
  ) async {
    return await _repository.verifyAnswer(
      entryId: params.entryId,
      verifiedBy: params.verifiedBy,
    );
  }
}
