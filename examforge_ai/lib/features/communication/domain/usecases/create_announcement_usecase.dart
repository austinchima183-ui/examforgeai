import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart' hide AnnouncementEntity, AnnouncementPriority, AnnouncementType;


class CreateAnnouncementParams extends Equatable {
  const CreateAnnouncementParams({
    required this.title,
    required this.body,
    this.announcementType = AnnouncementType.general,
    this.priority = AnnouncementPriority.normal,
    this.targetAudience,
    this.targetClassIds,
    this.isScheduled = false,
    this.scheduledAt,
    this.expiresAt,
  });

  final String title;
  final String body;
  final AnnouncementType announcementType;
  final AnnouncementPriority priority;
  final List<String>? targetAudience;
  final List<String>? targetClassIds;
  final bool isScheduled;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [
        title,
        body,
        announcementType,
        priority,
        targetAudience,
        targetClassIds,
        isScheduled,
        scheduledAt,
        expiresAt,
      ];
}

class CreateAnnouncementUseCase {
  CreateAnnouncementUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<AnnouncementEntity>> call(
    CreateAnnouncementParams params,
  ) async {
    if (params.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Announcement title cannot be empty',
          fieldErrors: {'title': 'Title is required'},
        ),
      );
    }

    if (params.body.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Announcement body cannot be empty',
          fieldErrors: {'body': 'Body is required'},
        ),
      );
    }

    if (params.isScheduled && params.scheduledAt == null) {
      return const FailureResult(
        Failure.validation(
          message: 'Scheduled announcements must have a scheduledAt date',
          fieldErrors: {'scheduledAt': 'Required when isScheduled is true'},
        ),
      );
    }

    return _repository.createAnnouncement(
      title: params.title,
      body: params.body,
      announcementType: params.announcementType,
      priority: params.priority,
      targetAudience: params.targetAudience,
      targetClassIds: params.targetClassIds,
      isScheduled: params.isScheduled,
      scheduledAt: params.scheduledAt,
      expiresAt: params.expiresAt,
    );
  }
}
