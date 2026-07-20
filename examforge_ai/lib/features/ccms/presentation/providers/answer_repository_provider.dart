import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/answer_repository_usecases.dart';

class AnswerRepositoryState extends Equatable {
  final AnswerRepositoryEntry? answerEntry;
  final bool isLoading;
  final String? error;

  const AnswerRepositoryState({this.answerEntry, this.isLoading = false, this.error});

  AnswerRepositoryState copyWith({AnswerRepositoryEntry? answerEntry, bool? isLoading, String? error}) {
    return AnswerRepositoryState(answerEntry: answerEntry ?? this.answerEntry, isLoading: isLoading ?? this.isLoading, error: error);
  }

  @override
  List<Object?> get props => [answerEntry, isLoading, error];
}

class AnswerRepositoryNotifier extends StateNotifier<AnswerRepositoryState> {
  final GetAnswerEntryUseCase _getAnswerEntryUseCase;
  final CreateAnswerEntryUseCase _createAnswerEntryUseCase;
  final UpdateAnswerEntryUseCase _updateAnswerEntryUseCase;
  final VerifyAnswerUseCase _verifyAnswerUseCase;

  AnswerRepositoryNotifier({
    required GetAnswerEntryUseCase getAnswerEntryUseCase,
    required CreateAnswerEntryUseCase createAnswerEntryUseCase,
    required UpdateAnswerEntryUseCase updateAnswerEntryUseCase,
    required VerifyAnswerUseCase verifyAnswerUseCase,
  })  : _getAnswerEntryUseCase = getAnswerEntryUseCase,
        _createAnswerEntryUseCase = createAnswerEntryUseCase,
        _updateAnswerEntryUseCase = updateAnswerEntryUseCase,
        _verifyAnswerUseCase = verifyAnswerUseCase,
        super(const AnswerRepositoryState());

  Future<void> loadAnswer(String contentItemId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getAnswerEntryUseCase(GetAnswerEntryParams(contentItemId: contentItemId));
    result.fold(
      onSuccess: (entry) => state = state.copyWith(answerEntry: entry, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> createAnswer(AnswerRepositoryEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createAnswerEntryUseCase(CreateAnswerEntryParams(entry: entry));
    result.fold(
      onSuccess: (created) => state = state.copyWith(answerEntry: created, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> updateAnswer(AnswerRepositoryEntry entry) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateAnswerEntryUseCase(UpdateAnswerEntryParams(entry: entry));
    result.fold(
      onSuccess: (updated) => state = state.copyWith(answerEntry: updated, isLoading: false),
      onFailure: (failure) => state = state.copyWith(isLoading: false, error: _mapFailureToMessage(failure)),
    );
  }

  Future<void> verifyAnswer({required String entryId, required String verifiedBy}) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _verifyAnswerUseCase(VerifyAnswerParams(entryId: entryId, verifiedBy: verifiedBy));
    result.fold(
      onSuccess: (verified) => state = state.copyWith(answerEntry: verified, isLoading: false),
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
