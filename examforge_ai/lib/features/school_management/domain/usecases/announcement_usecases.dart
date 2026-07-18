import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/school_management_entities.dart';
import '../repositories/school_management_repository.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE ANNOUNCEMENT
// ═══════════════════════════════════════════════════════════════════════

class CreateAnnouncementParams {
  const CreateAnnouncementParams({required this.announcement});
  final AnnouncementEntity announcement;
}

/// Use case that creates a new announcement.
///
/// Validates that [AnnouncementEntity.title], [AnnouncementEntity.content],
/// and [AnnouncementEntity.schoolId] are present, then delegates to
/// [SchoolManagementRepository.createAnnouncement].
class CreateAnnouncementUseCase {
  CreateAnnouncementUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AnnouncementEntity>> call(
    CreateAnnouncementParams params,
  ) async {
    // ── Validate title ───────────────────────────────────────────────────
    if (params.announcement.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Announcement title is required',
          fieldErrors: {'title': 'Please provide a title'},
        ),
      );
    }

    // ── Validate content ─────────────────────────────────────────────────
    if (params.announcement.content.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Announcement content is required',
          fieldErrors: {'content': 'Please provide the announcement content'},
        ),
      );
    }

    // ── Validate schoolId ────────────────────────────────────────────────
    if (params.announcement.schoolId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'School ID is required',
          fieldErrors: {'schoolId': 'Please select a school'},
        ),
      );
    }

    return _repository.createAnnouncement(params.announcement);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPDATE ANNOUNCEMENT
// ═══════════════════════════════════════════════════════════════════════

class UpdateAnnouncementParams {
  const UpdateAnnouncementParams({required this.announcement});
  final AnnouncementEntity announcement;
}

/// Use case that updates an existing announcement.
///
/// Delegates to [SchoolManagementRepository.updateAnnouncement].
class UpdateAnnouncementUseCase {
  UpdateAnnouncementUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<AnnouncementEntity>> call(
    UpdateAnnouncementParams params,
  ) async {
    return _repository.updateAnnouncement(params.announcement);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DELETE ANNOUNCEMENT
// ═══════════════════════════════════════════════════════════════════════

class DeleteAnnouncementParams {
  const DeleteAnnouncementParams({required this.announcementId});
  final String announcementId;
}

/// Use case that deletes an announcement.
///
/// Delegates to [SchoolManagementRepository.deleteAnnouncement].
class DeleteAnnouncementUseCase {
  DeleteAnnouncementUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(DeleteAnnouncementParams params) async {
    return _repository.deleteAnnouncement(params.announcementId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PUBLISH ANNOUNCEMENT
// ═══════════════════════════════════════════════════════════════════════

class PublishAnnouncementParams {
  const PublishAnnouncementParams({required this.announcementId});
  final String announcementId;
}

/// Use case that publishes an announcement, making it visible to the target audience.
///
/// Delegates to [SchoolManagementRepository.publishAnnouncement].
class PublishAnnouncementUseCase {
  PublishAnnouncementUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<void>> call(PublishAnnouncementParams params) async {
    return _repository.publishAnnouncement(params.announcementId);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GET ANNOUNCEMENTS
// ═══════════════════════════════════════════════════════════════════════

class GetAnnouncementsParams {
  const GetAnnouncementsParams({
    required this.schoolId,
    this.type,
    this.isPublished,
    this.page = 1,
    this.perPage = 20,
  });

  final String schoolId;
  final AnnouncementType? type;
  final bool? isPublished;
  final int page;
  final int perPage;
}

/// Use case that retrieves a paginated list of announcements.
///
/// Delegates to [SchoolManagementRepository.getAnnouncements].
class GetAnnouncementsUseCase {
  GetAnnouncementsUseCase(this._repository);
  final SchoolManagementRepository _repository;

  Future<Result<List<AnnouncementEntity>>> call(
    GetAnnouncementsParams params,
  ) async {
    return _repository.getAnnouncements(
      schoolId: params.schoolId,
      type: params.type,
      isPublished: params.isPublished,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
