import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';
import '../../domain/usecases/subject_usecases.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class SubjectState extends Equatable {
  final List<Subject> subjects;
  final String? selectedSubjectId;
  final List<Subject> levelSubjects;
  final bool isLoading;
  final String? error;

  const SubjectState({
    this.subjects = const [],
    this.selectedSubjectId,
    this.levelSubjects = const [],
    this.isLoading = false,
    this.error,
  });

  SubjectState copyWith({
    List<Subject>? subjects,
    String? selectedSubjectId,
    bool clearSelectedSubjectId = false,
    List<Subject>? levelSubjects,
    bool? isLoading,
    String? error,
  }) {
    return SubjectState(
      subjects: subjects ?? this.subjects,
      selectedSubjectId: clearSelectedSubjectId
          ? null
          : (selectedSubjectId ?? this.selectedSubjectId),
      levelSubjects: levelSubjects ?? this.levelSubjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [subjects, selectedSubjectId, levelSubjects, isLoading, error];
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class SubjectNotifier extends StateNotifier<SubjectState> {
  final GetSubjectsUseCase _getSubjectsUseCase;
  final GetSubjectByIdUseCase _getSubjectByIdUseCase;
  final CreateSubjectUseCase _createSubjectUseCase;
  final UpdateSubjectUseCase _updateSubjectUseCase;
  final DeleteSubjectUseCase _deleteSubjectUseCase;
  final GetLevelSubjectsUseCase _getLevelSubjectsUseCase;

  SubjectNotifier({
    required GetSubjectsUseCase getSubjectsUseCase,
    required GetSubjectByIdUseCase getSubjectByIdUseCase,
    required CreateSubjectUseCase createSubjectUseCase,
    required UpdateSubjectUseCase updateSubjectUseCase,
    required DeleteSubjectUseCase deleteSubjectUseCase,
    required GetLevelSubjectsUseCase getLevelSubjectsUseCase,
  })  : _getSubjectsUseCase = getSubjectsUseCase,
        _getSubjectByIdUseCase = getSubjectByIdUseCase,
        _createSubjectUseCase = createSubjectUseCase,
        _updateSubjectUseCase = updateSubjectUseCase,
        _deleteSubjectUseCase = deleteSubjectUseCase,
        _getLevelSubjectsUseCase = getLevelSubjectsUseCase,
        super(const SubjectState());

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

  Future<void> loadSubjects({
    String? schoolId,
    String? educationalLevelId,
    String? curriculumId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getSubjectsUseCase(GetSubjectsParams(
      schoolId: schoolId,
      educationalLevelId: educationalLevelId,
      curriculumId: curriculumId,
    ),);
    result.fold(
      onSuccess: (subjects) =>
          state = state.copyWith(subjects: subjects, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> loadLevelSubjects(String schoolId, String levelId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getLevelSubjectsUseCase(
      GetLevelSubjectsParams(educationalLevelId: levelId),
    );
    result.fold(
      onSuccess: (subjects) =>
          state = state.copyWith(levelSubjects: subjects, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> createSubject(Subject data) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createSubjectUseCase(
      CreateSubjectParams(subject: data),
    );
    result.fold(
      onSuccess: (created) => state = state.copyWith(
        subjects: [...state.subjects, created],
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> updateSubject(String id, Subject data) async {
    state = state.copyWith(isLoading: true, error: null);
    final updatedData = data.copyWith(id: id);
    final result = await _updateSubjectUseCase(
      UpdateSubjectParams(subject: updatedData),
    );
    result.fold(
      onSuccess: (updated) {
        final list = state.subjects
            .map((s) => s.id == updated.id ? updated : s)
            .toList();
        state = state.copyWith(subjects: list, isLoading: false);
      },
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  Future<void> deleteSubject(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _deleteSubjectUseCase(DeleteSubjectParams(id: id));
    result.fold(
      onSuccess: (_) => state = state.copyWith(
        subjects: state.subjects.where((s) => s.id != id).toList(),
        isLoading: false,
      ),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
    );
  }

  void selectSubject(String id) {
    final exists = state.subjects.any((s) => s.id == id);
    if (exists) {
      state = state.copyWith(selectedSubjectId: id);
    }
  }
}
