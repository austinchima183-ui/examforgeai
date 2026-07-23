import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../domain/repositories/school_management_repository.dart';


// ═══════════════════════════════════════════════════════════════════════
// CLASS LIST STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the class listing feature.
class ClassListState {
  const ClassListState({
    this.classes = const [],
    this.isLoading = false,
    this.error,
    this.academicYearFilter,
  });

  /// The list of classes.
  final List<ClassEntity> classes;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Filter by academic year.
  final String? academicYearFilter;

  /// Number of classes currently loaded.
  int get loadedCount => classes.length;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Creates a copy of this state with the given fields replaced.
  ClassListState copyWith({
    List<ClassEntity>? classes,
    bool? isLoading,
    String? error,
    String? academicYearFilter,
  }) {
    return ClassListState(
      classes: classes ?? this.classes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      academicYearFilter: academicYearFilter ?? this.academicYearFilter,
    );
  }

  /// Clears the current error message.
  ClassListState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CLASS LIST NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the class list feature's state.
class ClassListNotifier extends StateNotifier<ClassListState> {
  ClassListNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const ClassListState());

  final SchoolManagementRepository _repository;

  static const int _perPage = 20;

  // ─── Load Classes ──────────────────────────────────────────────────

  /// Loads classes for a school with optional filters.
  Future<void> loadClasses({
    required String schoolId,
    String? academicYear,
    bool? isActive,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getClasses(
      schoolId: schoolId,
      academicYear: academicYear ?? state.academicYearFilter,
      isActive: isActive,
      page: page,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (classes) {
        state = state.copyWith(
          isLoading: false,
          classes: classes,
          error: null,
        );
        AppLogger.info('Loaded ${classes.length} classes');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load classes: $failure');
      },
    );
  }

  // ─── Create Class ──────────────────────────────────────────────────

  /// Creates a new class.
  Future<void> createClass(ClassEntity classEntity) async {
    final result = await _repository.createClass(classEntity);

    result.fold(
      onSuccess: (createdClass) {
        final updatedList = [createdClass, ...state.classes];
        state = state.copyWith(classes: updatedList, error: null);
        AppLogger.info('Class created: ${createdClass.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create class: $failure');
      },
    );
  }

  // ─── Update Class ──────────────────────────────────────────────────

  /// Updates an existing class.
  Future<void> updateClass(ClassEntity classEntity) async {
    final result = await _repository.updateClass(classEntity);

    result.fold(
      onSuccess: (updatedClass) {
        final updatedList = state.classes
            .map((c) => c.id == updatedClass.id ? updatedClass : c)
            .toList();
        state = state.copyWith(classes: updatedList, error: null);
        AppLogger.info('Class updated: ${updatedClass.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to update class: $failure');
      },
    );
  }

  // ─── Assign Students ───────────────────────────────────────────────

  /// Assigns a list of students to a class.
  Future<void> assignStudents(String classId, List<String> studentIds) async {
    final result = await _repository.assignStudentsToClass(classId, studentIds);

    result.fold(
      onSuccess: (_) {
        // Update local class student count
        final updatedList = state.classes.map((c) {
          if (c.id == classId) {
            return c.copyWith(
              studentCount: c.studentCount + studentIds.length,
            );
          }
          return c;
        }).toList();
        state = state.copyWith(classes: updatedList, error: null);
        AppLogger.info(
          'Assigned ${studentIds.length} students to class: $classId',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to assign students: $failure');
      },
    );
  }

  // ─── Remove Student ────────────────────────────────────────────────

  /// Removes a student from a class.
  Future<void> removeStudent(String classId, String studentId) async {
    final result = await _repository.removeStudentFromClass(classId, studentId);

    result.fold(
      onSuccess: (_) {
        final updatedList = state.classes.map((c) {
          if (c.id == classId) {
            return c.copyWith(
              studentCount: c.studentCount > 0 ? c.studentCount - 1 : 0,
            );
          }
          return c;
        }).toList();
        state = state.copyWith(classes: updatedList, error: null);
        AppLogger.info('Removed student $studentId from class: $classId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to remove student: $failure');
      },
    );
  }

  // ─── Set Filter ────────────────────────────────────────────────────

  /// Sets the academic year filter.
  void setAcademicYearFilter(String? academicYear) {
    state = state.copyWith(academicYearFilter: academicYear);
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
// CLASS DETAIL STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the class detail feature.
class ClassDetailState {
  const ClassDetailState({
    this.classEntity,
    this.students = const [],
    this.subjects = const [],
    this.isLoading = false,
    this.error,
  });

  /// The currently viewed class, or `null`.
  final ClassEntity? classEntity;

  /// Students enrolled in this class.
  final List<StudentProfileEntity> students;

  /// Subjects assigned to this class.
  final List<SubjectEntity> subjects;

  /// Whether the detail is loading.
  final bool isLoading;

  /// The most recent error message, or `null`.
  final String? error;

  /// Whether the class data has been loaded.
  bool get isLoaded => classEntity != null;

  /// Creates a copy of this state with the given fields replaced.
  ClassDetailState copyWith({
    ClassEntity? classEntity,
    List<StudentProfileEntity>? students,
    List<SubjectEntity>? subjects,
    bool? isLoading,
    String? error,
  }) {
    return ClassDetailState(
      classEntity: classEntity ?? this.classEntity,
      students: students ?? this.students,
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Clears the current error message.
  ClassDetailState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// CLASS DETAIL NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the class detail feature's state.
class ClassDetailNotifier extends StateNotifier<ClassDetailState> {
  ClassDetailNotifier({
    required SchoolManagementRepository schoolManagementRepository,
  })  : _repository = schoolManagementRepository,
        super(const ClassDetailState());

  final SchoolManagementRepository _repository;

  // ─── Load Class ────────────────────────────────────────────────────

  /// Loads a class by ID.
  Future<void> loadClass(String classId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getClass(classId);

    result.fold(
      onSuccess: (classEntity) {
        state = state.copyWith(
          isLoading: false,
          classEntity: classEntity,
          error: null,
        );
        AppLogger.info('Loaded class detail: $classId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load class: $failure');
      },
    );
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

/// Provides the [ClassListNotifier] and its [ClassListState].
final classListProvider =
    StateNotifierProvider<ClassListNotifier, ClassListState>((ref) {
  return ClassListNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});

/// Provides the [ClassDetailNotifier] and its [ClassDetailState].
final classDetailProvider =
    StateNotifierProvider<ClassDetailNotifier, ClassDetailState>((ref) {
  return ClassDetailNotifier(
    schoolManagementRepository: ref.watch(schoolManagementRepositoryProvider),
  );
});
