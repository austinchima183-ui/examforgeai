import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';
import '../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SUBJECT LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the subject listing feature.
class SubjectListState {
  const SubjectListState({
    this.subjects = const [],
    this.isLoading = false,
    this.error,
    this.categoryFilter,
  });

  /// The list of subjects.
  final List<SubjectEntity> subjects;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by subject category.
  final String? categoryFilter;

  /// Number of subjects currently loaded.
  int get loadedCount => subjects.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  SubjectListState copyWith({
    List<SubjectEntity>? subjects,
    bool? isLoading,
    String? error,
    String? categoryFilter,
  }) {
    return SubjectListState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  /// Clears the current error message.
  SubjectListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// SUBJECT LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the subject list feature's state.
class SubjectListNotifier extends StateNotifier<SubjectListState> {
  SubjectListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const SubjectListState());

  final SchoolManagementRepository _repository;

  // ─── Load Subjects ─────────────────────────────────────────────────

  /// Loads subjects with optional filters.
  Future<void> loadSubjects({
    String? schoolId,
    String? category,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSubjects(
      schoolId: schoolId,
      category: category ?? state.categoryFilter,
      isActive: isActive,
    );

    result.fold(
      onSuccess: (subjects) {
        state = state.copyWith(
          isLoading: false,
          subjects: subjects,
          error: null,
        );
        AppLogger.info('Loaded ${subjects.length} subjects');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load subjects: $failure');
      },
    );
  }

  // ─── Create Subject ────────────────────────────────────────────────

  /// Creates a new subject.
  Future<void> createSubject(SubjectEntity subject) async {
    final result = await _repository.createSubject(subject);

    result.fold(
      onSuccess: (createdSubject) {
        final updatedList = [createdSubject, ...state.subjects];
        state = state.copyWith(subjects: updatedList, error: null);
        AppLogger.info('Subject created: ${createdSubject.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create subject: $failure');
      },
    );
  }

  // ─── Update Subject ────────────────────────────────────────────────

  /// Updates an existing subject.
  Future<void> updateSubject(SubjectEntity subject) async {
    final result = await _repository.updateSubject(subject);

    result.fold(
      onSuccess: (updatedSubject) {
        final updatedList = state.subjects
            .map((s) => s.id == updatedSubject.id ? updatedSubject : s)
            .toList();
        state = state.copyWith(subjects: updatedList, error: null);
        AppLogger.info('Subject updated: ${updatedSubject.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update subject: $failure');
      },
    );
  }

  // ─── Assign Teacher ────────────────────────────────────────────────

  /// Assigns a teacher to a subject for a specific class.
  Future<void> assignTeacher({
    required String classId,
    required String subjectId,
    required String teacherId,
  }) async {
    final result = await _repository.assignTeacherToSubject(
      classId: classId,
      subjectId: subjectId,
      teacherId: teacherId,
    );

    result.fold(
      onSuccess: (_) {
        // Update local subject with assigned teacher
        final updatedList = state.subjects.map((s) {
          if (s.id == subjectId) {
            final updatedTeacherIds = {...s.assignedTeacherIds, teacherId};
            final updatedClassIds = {...s.assignedClassIds, classId};
            return s.copyWith(
              assignedTeacherIds: updatedTeacherIds.toList(),
              assignedClassIds: updatedClassIds.toList(),
            );
          }
          return s;
        }).toList();
        state = state.copyWith(subjects: updatedList, error: null);
        AppLogger.info(
          'Teacher $teacherId assigned to subject $subjectId for class $classId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to assign teacher: $failure');
      },
    );
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Sets the category filter.
  void setCategoryFilter(String? category) {
    state = state.copyWith(categoryFilter: category);
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [SubjectListNotifier] and its [SubjectListState].
final subjectListProvider =
    StateNotifierProvider<SubjectListNotifier, SubjectListState>((ref) {
  return SubjectListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
