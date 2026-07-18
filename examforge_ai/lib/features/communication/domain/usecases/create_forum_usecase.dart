import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class CreateForumParams extends Equatable {
  const CreateForumParams({
    required this.name,
    this.description,
    this.forumType = ForumType.schoolCommunity,
    this.classId,
    this.subjectId,
    this.departmentId,
  });

  final String name;
  final String? description;
  final ForumType forumType;
  final String? classId;
  final String? subjectId;
  final String? departmentId;

  @override
  List<Object?> get props => [name, description, forumType, classId, subjectId, departmentId];
}

class CreateForumUseCase {
  CreateForumUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<DiscussionForumEntity>> call(CreateForumParams params) async {
    if (params.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Forum name cannot be empty',
          fieldErrors: {'name': 'Name is required'},
        ),
      );
    }

    return _repository.createForum(
      name: params.name,
      description: params.description,
      forumType: params.forumType,
      classId: params.classId,
      subjectId: params.subjectId,
      departmentId: params.departmentId,
    );
  }
}
