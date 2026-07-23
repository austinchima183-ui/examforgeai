import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/curriculum_usecases.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class CurriculumState extends Equatable {
  final List<Curriculum> curricula;
  final String? selectedCurriculumId;
  final List<CurriculumVersion> versions;
  final List<CurriculumLevelMapping> levelMappings;
  final bool isLoading;
  final String? error;

  const CurriculumState({
    this.curricula = const [],
    this.selectedCurriculumId,
    this.versions = const [],
    this.levelMappings = const [],
    this.isLoading = false,
    this.error,
  });

  CurriculumState copyWith({
    List<Curriculum>? curricula,
    String? selectedCurriculumId,
    bool clearSelectedCurriculumId = false,
    List<CurriculumVersion>? versions,
    List<CurriculumLevelMapping>? levelMappings,
    bool? isLoading,
    String? error,
  }) {
    return CurriculumState(
      curricula: curricula ?? this.curricula,
      selectedCurriculumId: clearSelectedCurriculumId
          ? null
          : (selectedCurriculumId ?? this.selectedCurriculumId),
      versions: versions ?? this.versions,
      levelMappings: levelMappings ?? this.levelMappings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        curricula,
        selectedCurriculumId,
        versions,
        levelMappings,
        isLoading,
        error,
      ];
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class CurriculumNotifier extends StateNotifier<CurriculumState> {
  final GetCurriculaUseCase _getCurriculaUseCase;
  final GetCurriculumByIdUseCase _getCurriculumByIdUseCase;
  final CreateCurriculumUseCase _createCurriculumUseCase;
  final UpdateCurriculumUseCase _updateCurriculumUseCase;
  final GetCurriculumVersionsUseCase _getCurriculumVersionsUseCase;
  final GetCurriculumLevelMappingsUseCase _getCurriculumLevelMappingsUseCase;

  CurriculumNotifier({
    required GetCurriculaUseCase getCurriculaUseCase,
    required GetCurriculumByIdUseCase getCurriculumByIdUseCase,
    required CreateCurriculumUseCase createCurriculumUseCase,
    required UpdateCurriculumUseCase updateCurriculumUseCase,
    required GetCurriculumVersionsUseCase getCurriculumVersionsUseCase,
    required GetCurriculumLevelMappingsUseCase getCurriculumLevelMappingsUseCase,
  })  : _getCurriculaUseCase = getCurriculaUseCase,
        _getCurriculumByIdUseCase = getCurriculumByIdUseCase,
        _createCurriculumUseCase = createCurriculumUseCase,
        _updateCurriculumUseCase = updateCurriculumUseCase,
        _getCurriculumVersionsUseCase = getCurriculumVersionsUseCase,
        _getCurriculumLevelMappingsUseCase = getCurriculumLevelMappingsUseCase,
        super(const CurriculumState());

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

  Future<void> loadCurricula({
    String? countryCode,
    CurriculumType? curriculumType,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCurriculaUseCase(GetCurriculaParams(
      countryCode: countryCode,
      curriculumType: curriculumType,
      isActive: isActive,
    ),);
    result.fold(
      onSuccess: (curricula) =>
          state = state.copyWith(curricula: curricula, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  void selectCurriculum(String id) {
    final exists = state.curricula.any((c) => c.id == id);
    if (exists) {
      state = state.copyWith(selectedCurriculumId: id);
    }
  }

  Future<void> loadVersions(String curriculumId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCurriculumVersionsUseCase(
      GetCurriculumVersionsParams(curriculumId: curriculumId),
    );
    result.fold(
      onSuccess: (versions) =>
          state = state.copyWith(versions: versions, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadLevelMappings(String curriculumId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getCurriculumLevelMappingsUseCase(
      GetCurriculumLevelMappingsParams(curriculumId: curriculumId),
    );
    result.fold(
      onSuccess: (mappings) =>
          state = state.copyWith(levelMappings: mappings, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> createCurriculum(Curriculum data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createCurriculumUseCase(
      CreateCurriculumParams(curriculum: data),
    );
    result.fold(
      onSuccess: (created) => state = state.copyWith(
        curricula: [...state.curricula, created],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> updateCurriculum(String id, Curriculum data) async {
    state = state.copyWith(isLoading: true, error: null);
    final updatedData = data.copyWith(id: id);
    final result = await _updateCurriculumUseCase(
      UpdateCurriculumParams(curriculum: updatedData),
    );
    result.fold(
      onSuccess: (updated) {
        final list = state.curricula
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        state = state.copyWith(
          curricula: list,
          selectedCurriculumId: updated.id,
          isLoading: false,
        );
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }
}
