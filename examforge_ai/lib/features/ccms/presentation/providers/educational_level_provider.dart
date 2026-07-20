import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/educational_level_usecases.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class EducationalLevelState extends Equatable {
  final List<EducationalLevel> levels;
  final List<SchoolLevelConfiguration> schoolLevels;
  final String? selectedLevelId;
  final bool isLoading;
  final String? error;

  const EducationalLevelState({
    this.levels = const [],
    this.schoolLevels = const [],
    this.selectedLevelId,
    this.isLoading = false,
    this.error,
  });

  EducationalLevelState copyWith({
    List<EducationalLevel>? levels,
    List<SchoolLevelConfiguration>? schoolLevels,
    String? selectedLevelId,
    bool clearSelectedLevelId = false,
    bool? isLoading,
    String? error,
  }) {
    return EducationalLevelState(
      levels: levels ?? this.levels,
      schoolLevels: schoolLevels ?? this.schoolLevels,
      selectedLevelId: clearSelectedLevelId ? null : (selectedLevelId ?? this.selectedLevelId),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [levels, schoolLevels, selectedLevelId, isLoading, error];
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class EducationalLevelNotifier extends StateNotifier<EducationalLevelState> {
  final GetEducationalLevelsUseCase _getEducationalLevelsUseCase;
  final GetSchoolLevelsUseCase _getSchoolLevelsUseCase;
  final ConfigureSchoolLevelUseCase _configureSchoolLevelUseCase;
  final UpdateSchoolLevelConfigurationUseCase _updateSchoolLevelConfigurationUseCase;

  EducationalLevelNotifier({
    required GetEducationalLevelsUseCase getEducationalLevelsUseCase,
    required GetSchoolLevelsUseCase getSchoolLevelsUseCase,
    required ConfigureSchoolLevelUseCase configureSchoolLevelUseCase,
    required UpdateSchoolLevelConfigurationUseCase updateSchoolLevelConfigurationUseCase,
  })  : _getEducationalLevelsUseCase = getEducationalLevelsUseCase,
        _getSchoolLevelsUseCase = getSchoolLevelsUseCase,
        _configureSchoolLevelUseCase = configureSchoolLevelUseCase,
        _updateSchoolLevelConfigurationUseCase = updateSchoolLevelConfigurationUseCase,
        super(const EducationalLevelState());

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

  Future<void> loadEducationalLevels() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getEducationalLevelsUseCase();
    result.fold(
      onSuccess: (levels) => state = state.copyWith(levels: levels, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadSchoolLevels(String schoolId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSchoolLevelsUseCase(
      GetSchoolLevelsParams(schoolId: schoolId),
    );
    result.fold(
      onSuccess: (configs) => state = state.copyWith(schoolLevels: configs, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> configureSchoolLevel(
    String schoolId,
    String levelId,
    bool isEnabled,
    String? customName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    final config = SchoolLevelConfiguration(
      id: '',
      schoolId: schoolId,
      educationalLevelId: levelId,
      isEnabled: isEnabled,
      customName: customName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final result = await _configureSchoolLevelUseCase(
      ConfigureSchoolLevelParams(configuration: config),
    );
    result.fold(
      onSuccess: (updated) {
        final updatedList = [...state.schoolLevels];
        final idx = updatedList.indexWhere((e) => e.educationalLevelId == levelId);
        if (idx >= 0) {
          updatedList[idx] = updated;
        } else {
          updatedList.add(updated);
        }
        state = state.copyWith(schoolLevels: updatedList, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> updateSchoolLevelConfiguration(
    SchoolLevelConfiguration configuration,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateSchoolLevelConfigurationUseCase(
      UpdateSchoolLevelConfigurationParams(configuration: configuration),
    );
    result.fold(
      onSuccess: (updated) {
        final updatedList = state.schoolLevels.map((e) {
          return e.id == updated.id ? updated : e;
        }).toList();
        state = state.copyWith(schoolLevels: updatedList, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  void selectLevel(String levelId) {
    final exists = state.levels.any((l) => l.id == levelId);
    if (exists) {
      state = state.copyWith(selectedLevelId: levelId);
    }
  }
}
