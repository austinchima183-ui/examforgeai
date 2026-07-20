import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/ai_curriculum_usecases.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class AiCurriculumState extends Equatable {
  final List<AiCurriculumConfig> configs;
  final List<AiGenerationRule> generationRules;
  final AiCurriculumConfig? selectedConfig;
  final bool isLoading;
  final String? error;

  const AiCurriculumState({
    this.configs = const [],
    this.generationRules = const [],
    this.selectedConfig,
    this.isLoading = false,
    this.error,
  });

  AiCurriculumState copyWith({
    List<AiCurriculumConfig>? configs,
    List<AiGenerationRule>? generationRules,
    AiCurriculumConfig? selectedConfig,
    bool clearSelectedConfig = false,
    bool? isLoading,
    String? error,
  }) {
    return AiCurriculumState(
      configs: configs ?? this.configs,
      generationRules: generationRules ?? this.generationRules,
      selectedConfig:
          clearSelectedConfig ? null : (selectedConfig ?? this.selectedConfig),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        configs,
        generationRules,
        selectedConfig,
        isLoading,
        error,
      ];
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class AiCurriculumNotifier extends StateNotifier<AiCurriculumState> {
  final GetAiCurriculumConfigUseCase _getConfigUseCase;
  final UpsertAiCurriculumConfigUseCase _upsertConfigUseCase;
  final GetAiGenerationRulesUseCase _getRulesUseCase;
  final CreateAiGenerationRuleUseCase _createRuleUseCase;
  final UpdateAiGenerationRuleUseCase _updateRuleUseCase;

  AiCurriculumNotifier({
    required GetAiCurriculumConfigUseCase getConfigUseCase,
    required UpsertAiCurriculumConfigUseCase upsertConfigUseCase,
    required GetAiGenerationRulesUseCase getRulesUseCase,
    required CreateAiGenerationRuleUseCase createRuleUseCase,
    required UpdateAiGenerationRuleUseCase updateRuleUseCase,
  })  : _getConfigUseCase = getConfigUseCase,
        _upsertConfigUseCase = upsertConfigUseCase,
        _getRulesUseCase = getRulesUseCase,
        _createRuleUseCase = createRuleUseCase,
        _updateRuleUseCase = updateRuleUseCase,
        super(const AiCurriculumState());

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

  Future<void> loadConfig({
    required String schoolId,
    required String subjectId,
    required String educationalLevelId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getConfigUseCase(GetAiCurriculumConfigParams(
      schoolId: schoolId,
      subjectId: subjectId,
      educationalLevelId: educationalLevelId,
    ));
    result.fold(
      onSuccess: (config) {
        final updatedConfigs = [...state.configs];
        final existingIdx =
            updatedConfigs.indexWhere((c) => c.id == config.id);
        if (existingIdx >= 0) {
          updatedConfigs[existingIdx] = config;
        } else {
          updatedConfigs.add(config);
        }
        state = state.copyWith(
          configs: updatedConfigs,
          selectedConfig: config,
          isLoading: false,
        );
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> upsertConfig(AiCurriculumConfig data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _upsertConfigUseCase(
      UpsertAiCurriculumConfigParams(config: data),
    );
    result.fold(
      onSuccess: (updated) {
        final updatedConfigs = [...state.configs];
        final existingIdx =
            updatedConfigs.indexWhere((c) => c.id == updated.id);
        if (existingIdx >= 0) {
          updatedConfigs[existingIdx] = updated;
        } else {
          updatedConfigs.add(updated);
        }
        state = state.copyWith(
          configs: updatedConfigs,
          selectedConfig: updated,
          isLoading: false,
        );
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadGenerationRules({
    String? educationalLevelId,
    String? subjectId,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getRulesUseCase(GetAiGenerationRulesParams(
      educationalLevelId: educationalLevelId,
      subjectId: subjectId,
      isActive: isActive,
    ));
    result.fold(
      onSuccess: (rules) =>
          state = state.copyWith(generationRules: rules, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> createGenerationRule(AiGenerationRule data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createRuleUseCase(
      CreateAiGenerationRuleParams(rule: data),
    );
    result.fold(
      onSuccess: (created) => state = state.copyWith(
        generationRules: [...state.generationRules, created],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> updateGenerationRule(String id, AiGenerationRule data) async {
    state = state.copyWith(isLoading: true, error: null);
    final updatedData = data.copyWith(id: id);
    final result = await _updateRuleUseCase(
      UpdateAiGenerationRuleParams(rule: updatedData),
    );
    result.fold(
      onSuccess: (updated) {
        final list = state.generationRules
            .map((r) => r.id == updated.id ? updated : r)
            .toList();
        state = state.copyWith(generationRules: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }
}
