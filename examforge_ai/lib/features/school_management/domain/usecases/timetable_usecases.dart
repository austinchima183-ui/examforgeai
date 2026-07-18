import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE TIMETABLE
// ═══════════════════════════════════════════════════════════════════════

class CreateTimetableParams {
  const CreateTimetableParams({required this.timetable});
  final TimetableEntity timetable;
}

/// Use case that creates a new timetable.
///
/// Delegates to [SchoolManagementRepository.createTimetable].
class CreateTimetableUseCase {
  CreateTimetableUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TimetableEntity>> call(CreateTimetableParams params) async {
    return _repository.createTimetable(params.timetable);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE TIMETABLE
// ═══════════════════════════════════════════════════════════════════════

class UpdateTimetableParams {
  const UpdateTimetableParams({required this.timetable});
  final TimetableEntity timetable;
}

/// Use case that updates an existing timetable.
///
/// Delegates to [SchoolManagementRepository.updateTimetable].
class UpdateTimetableUseCase {
  UpdateTimetableUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TimetableEntity>> call(UpdateTimetableParams params) async {
    return _repository.updateTimetable(params.timetable);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET TIMETABLE
// ═══════════════════════════════════════════════════════════════════════

class GetTimetableParams {
  const GetTimetableParams({required this.timetableId});
  final String timetableId;
}

/// Use case that retrieves a single timetable by ID.
///
/// Delegates to [SchoolManagementRepository.getTimetable].
class GetTimetableUseCase {
  GetTimetableUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TimetableEntity>> call(GetTimetableParams params) async {
    return _repository.getTimetable(params.timetableId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET TIMETABLES
// ═══════════════════════════════════════════════════════════════════════

class GetTimetablesParams {
  const GetTimetablesParams({
    required this.schoolId,
    this.termId,
    this.classId,
  });

  final String schoolId;
  final String? termId;
  final String? classId;
}

/// Use case that retrieves timetables filtered by school, term, or class.
///
/// Delegates to [SchoolManagementRepository.getTimetables].
class GetTimetablesUseCase {
  GetTimetablesUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<TimetableEntity>>> call(
    GetTimetablesParams params,
  ) async {
    return _repository.getTimetables(
      schoolId: params.schoolId,
      termId: params.termId,
      classId: params.classId,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ADD TIMETABLE SLOT
// ═══════════════════════════════════════════════════════════════════════

class AddTimetableSlotParams {
  const AddTimetableSlotParams({required this.slot});
  final TimetableSlotEntity slot;
}

/// Use case that adds a new slot to a timetable.
///
/// Validates that [TimetableSlotEntity.dayOfWeek], [TimetableSlotEntity.periodNumber],
/// [TimetableSlotEntity.startTime], and [TimetableSlotEntity.endTime] are present.
/// Also checks for scheduling conflicts before delegating to
/// [SchoolManagementRepository.addTimetableSlot].
class AddTimetableSlotUseCase {
  AddTimetableSlotUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TimetableSlotEntity>> call(
    AddTimetableSlotParams params,
  ) async {
    // ── dayOfWeek is a DayOfWeek enum, always non-null by construction ──

    // ── Validate periodNumber ────────────────────────────────────────────
    if (params.slot.periodNumber <= 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Period number is required',
          fieldErrors: {'periodNumber': 'Period number must be greater than zero'},
        ),
      );
    }

    // ── Validate startTime before endTime ─────────────────────────────────
    if (params.slot.endTime.isBefore(params.slot.startTime) ||
        params.slot.endTime.isAtSameMomentAs(params.slot.startTime)) {
      return const FailureResult(
        Failure.validation(
          message: 'End time must be after start time',
          fieldErrors: {
            'endTime': 'Slot end time must be later than start time',
          },
        ),
      );
    }

    // ── Check for conflicts ─────────────────────────────────────────────
    final conflictResult = await _repository.checkSlotConflicts(params.slot);
    if (conflictResult.isSuccess) {
      final conflicts = conflictResult.getOrElse(const []);
      if (conflicts.isNotEmpty) {
        return const FailureResult(
          Failure.validation(
            message: 'Timetable slot conflicts with an existing slot',
            fieldErrors: {
              'slot': 'This time slot conflicts with an existing entry',
            },
          ),
        );
      }
    }

    return _repository.addTimetableSlot(params.slot);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE TIMETABLE SLOT
// ═══════════════════════════════════════════════════════════════════════

class UpdateTimetableSlotParams {
  const UpdateTimetableSlotParams({required this.slot});
  final TimetableSlotEntity slot;
}

/// Use case that updates an existing timetable slot.
///
/// Delegates to [SchoolManagementRepository.updateTimetableSlot].
class UpdateTimetableSlotUseCase {
  UpdateTimetableSlotUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TimetableSlotEntity>> call(
    UpdateTimetableSlotParams params,
  ) async {
    return _repository.updateTimetableSlot(params.slot);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DELETE TIMETABLE SLOT
// ═══════════════════════════════════════════════════════════════════════

class DeleteTimetableSlotParams {
  const DeleteTimetableSlotParams({required this.slotId});
  final String slotId;
}

/// Use case that deletes a timetable slot.
///
/// Delegates to [SchoolManagementRepository.deleteTimetableSlot].
class DeleteTimetableSlotUseCase {
  DeleteTimetableSlotUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(DeleteTimetableSlotParams params) async {
    return _repository.deleteTimetableSlot(params.slotId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PUBLISH TIMETABLE
// ═══════════════════════════════════════════════════════════════════════

class PublishTimetableParams {
  const PublishTimetableParams({required this.timetableId});
  final String timetableId;
}

/// Use case that publishes a timetable, making it visible to students/teachers.
///
/// Delegates to [SchoolManagementRepository.publishTimetable].
class PublishTimetableUseCase {
  PublishTimetableUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(PublishTimetableParams params) async {
    return _repository.publishTimetable(params.timetableId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHECK SLOT CONFLICTS
// ═══════════════════════════════════════════════════════════════════════

class CheckSlotConflictsParams {
  const CheckSlotConflictsParams({required this.slot});
  final TimetableSlotEntity slot;
}

/// Use case that checks whether a proposed timetable slot conflicts with
/// existing slots for the same class, teacher, or room.
///
/// Delegates to [SchoolManagementRepository.checkSlotConflicts].
class CheckSlotConflictsUseCase {
  CheckSlotConflictsUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<TimetableSlotEntity>>> call(
    CheckSlotConflictsParams params,
  ) async {
    return _repository.checkSlotConflicts(params.slot);
  }
}
