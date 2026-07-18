import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE SESSION
// ═══════════════════════════════════════════════════════════════════════

class CreateSessionParams {
  const CreateSessionParams({required this.session});
  final AcademicSessionEntity session;
}

/// Use case that creates a new academic session.
///
/// Validates that [AcademicSessionEntity.name], [AcademicSessionEntity.sessionYear],
/// [AcademicSessionEntity.schoolId], [AcademicSessionEntity.startDate], and
/// [AcademicSessionEntity.endDate] are present, then delegates to
/// [SchoolManagementRepository.createSession].
class CreateSessionUseCase {
  CreateSessionUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AcademicSessionEntity>> call(
    CreateSessionParams params,
  ) async {
    // ── Validate name ────────────────────────────────────────────────────
    if (params.session.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Session name is required',
          fieldErrors: {'name': 'Please provide a session name'},
        ),
      );
    }

    // ── Validate sessionYear ─────────────────────────────────────────────
    if (params.session.sessionYear.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Session year is required',
          fieldErrors: {'sessionYear': 'Please provide a session year'},
        ),
      );
    }

    // ── Validate schoolId ────────────────────────────────────────────────
    if (params.session.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Please select a school'},
        ),
      );
    }

    // ── Validate startDate ───────────────────────────────────────────────
    if (params.session.startDate.isAfter(params.session.endDate)) {
      return const FailureResult(
        Failure.validation(
          message: 'Start date must be before end date',
          fieldErrors: {'startDate': 'Session start date must precede end date'},
        ),
      );
    }

    return _repository.createSession(params.session);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE SESSION
// ═══════════════════════════════════════════════════════════════════════

class UpdateSessionParams {
  const UpdateSessionParams({required this.session});
  final AcademicSessionEntity session;
}

/// Use case that updates an existing academic session.
///
/// Delegates to [SchoolManagementRepository.updateSession].
class UpdateSessionUseCase {
  UpdateSessionUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AcademicSessionEntity>> call(
    UpdateSessionParams params,
  ) async {
    return _repository.updateSession(params.session);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET CURRENT SESSION
// ═══════════════════════════════════════════════════════════════════════

class GetCurrentSessionParams {
  const GetCurrentSessionParams({required this.schoolId});
  final String schoolId;
}

/// Use case that retrieves the current academic session for a school.
///
/// Delegates to [SchoolManagementRepository.getCurrentSession].
class GetCurrentSessionUseCase {
  GetCurrentSessionUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AcademicSessionEntity>> call(
    GetCurrentSessionParams params,
  ) async {
    return _repository.getCurrentSession(params.schoolId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SET CURRENT SESSION
// ═══════════════════════════════════════════════════════════════════════

class SetCurrentSessionParams {
  const SetCurrentSessionParams({required this.sessionId});
  final String sessionId;
}

/// Use case that sets the current academic session.
///
/// Delegates to [SchoolManagementRepository.setCurrentSession].
class SetCurrentSessionUseCase {
  SetCurrentSessionUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(SetCurrentSessionParams params) async {
    return _repository.setCurrentSession(params.sessionId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE TERM
// ═══════════════════════════════════════════════════════════════════════

class CreateTermParams {
  const CreateTermParams({required this.term});
  final TermEntity term;
}

/// Use case that creates a new term.
///
/// Validates that [TermEntity.name], [TermEntity.termType],
/// [TermEntity.schoolId], [TermEntity.startDate], and
/// [TermEntity.endDate] are present, then delegates to
/// [SchoolManagementRepository.createTerm].
class CreateTermUseCase {
  CreateTermUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TermEntity>> call(CreateTermParams params) async {
    // ── Validate name ────────────────────────────────────────────────────
    if (params.term.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Term name is required',
          fieldErrors: {'name': 'Please provide a term name'},
        ),
      );
    }

    // ── Validate termType ────────────────────────────────────────────────
    // TermType is an enum so it is always non-null, but we validate that
    // it is not a default/undefined value. The enum itself guarantees validity.

    // ── Validate schoolId ────────────────────────────────────────────────
    if (params.term.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Please select a school'},
        ),
      );
    }

    // ── Validate startDate / endDate ─────────────────────────────────────
    if (params.term.startDate.isAfter(params.term.endDate)) {
      return const FailureResult(
        Failure.validation(
          message: 'Start date must be before end date',
          fieldErrors: {'startDate': 'Term start date must precede end date'},
        ),
      );
    }

    return _repository.createTerm(params.term);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE TERM
// ═══════════════════════════════════════════════════════════════════════

class UpdateTermParams {
  const UpdateTermParams({required this.term});
  final TermEntity term;
}

/// Use case that updates an existing term.
///
/// Delegates to [SchoolManagementRepository.updateTerm].
class UpdateTermUseCase {
  UpdateTermUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TermEntity>> call(UpdateTermParams params) async {
    return _repository.updateTerm(params.term);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET CURRENT TERM
// ═══════════════════════════════════════════════════════════════════════

class GetCurrentTermParams {
  const GetCurrentTermParams({required this.schoolId});
  final String schoolId;
}

/// Use case that retrieves the current term for a school.
///
/// Delegates to [SchoolManagementRepository.getCurrentTerm].
class GetCurrentTermUseCase {
  GetCurrentTermUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<TermEntity>> call(GetCurrentTermParams params) async {
    return _repository.getCurrentTerm(params.schoolId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SET CURRENT TERM
// ═══════════════════════════════════════════════════════════════════════

class SetCurrentTermParams {
  const SetCurrentTermParams({required this.termId});
  final String termId;
}

/// Use case that sets the current term.
///
/// Delegates to [SchoolManagementRepository.setCurrentTerm].
class SetCurrentTermUseCase {
  SetCurrentTermUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(SetCurrentTermParams params) async {
    return _repository.setCurrentTerm(params.termId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CREATE CALENDAR EVENT
// ═══════════════════════════════════════════════════════════════════════

class CreateCalendarEventParams {
  const CreateCalendarEventParams({required this.event});
  final CalendarEventEntity event;
}

/// Use case that creates a new calendar event.
///
/// Delegates to [SchoolManagementRepository.createCalendarEvent].
class CreateCalendarEventUseCase {
  CreateCalendarEventUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<CalendarEventEntity>> call(
    CreateCalendarEventParams params,
  ) async {
    return _repository.createCalendarEvent(params.event);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE CALENDAR EVENT
// ═══════════════════════════════════════════════════════════════════════

class UpdateCalendarEventParams {
  const UpdateCalendarEventParams({required this.event});
  final CalendarEventEntity event;
}

/// Use case that updates an existing calendar event.
///
/// Delegates to [SchoolManagementRepository.updateCalendarEvent].
class UpdateCalendarEventUseCase {
  UpdateCalendarEventUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<CalendarEventEntity>> call(
    UpdateCalendarEventParams params,
  ) async {
    return _repository.updateCalendarEvent(params.event);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET CALENDAR EVENTS
// ═══════════════════════════════════════════════════════════════════════

class GetCalendarEventsParams {
  const GetCalendarEventsParams({
    required this.schoolId,
    this.termId,
    this.startDate,
    this.endDate,
    this.eventType,
  });

  final String schoolId;
  final String? termId;
  final DateTime? startDate;
  final DateTime? endDate;
  final CalendarEventType? eventType;
}

/// Use case that retrieves calendar events for a school.
///
/// Delegates to [SchoolManagementRepository.getCalendarEvents].
class GetCalendarEventsUseCase {
  GetCalendarEventsUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<CalendarEventEntity>>> call(
    GetCalendarEventsParams params,
  ) async {
    return _repository.getCalendarEvents(
      schoolId: params.schoolId,
      termId: params.termId,
      startDate: params.startDate,
      endDate: params.endDate,
      eventType: params.eventType,
    );
  }
}
