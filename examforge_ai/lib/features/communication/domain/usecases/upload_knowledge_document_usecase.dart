import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class UploadKnowledgeDocumentParams extends Equatable {
  const UploadKnowledgeDocumentParams({
    required this.title,
    required this.fileName,
    required this.fileUrl,
    this.description,
    this.documentType = 'policy',
    this.tags,
  });

  final String title;
  final String fileName;
  final String fileUrl;
  final String? description;
  final String documentType;
  final List<String>? tags;

  @override
  List<Object?> get props => [title, fileName, fileUrl, description, documentType, tags];
}

class UploadKnowledgeDocumentUseCase {
  UploadKnowledgeDocumentUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<SchoolKnowledgeDocumentEntity>> call(
    UploadKnowledgeDocumentParams params,
  ) async {
    if (params.title.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Document title cannot be empty',
          fieldErrors: {'title': 'Title is required'},
        ),
      );
    }

    if (params.fileName.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'File name cannot be empty',
          fieldErrors: {'fileName': 'File name is required'},
        ),
      );
    }

    if (params.fileUrl.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'File URL cannot be empty',
          fieldErrors: {'fileUrl': 'File URL is required'},
        ),
      );
    }

    return _repository.uploadKnowledgeDocument(
      title: params.title,
      fileName: params.fileName,
      fileUrl: params.fileUrl,
      description: params.description,
      documentType: params.documentType,
      tags: params.tags,
    );
  }
}
