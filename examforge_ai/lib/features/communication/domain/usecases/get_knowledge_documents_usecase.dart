import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/communication_entities.dart';
import '../repositories/communication_repository.dart';

class GetKnowledgeDocumentsParams extends Equatable {
  const GetKnowledgeDocumentsParams({
    this.documentType,
    this.page = 1,
    this.perPage = 20,
  });

  final String? documentType;
  final int page;
  final int perPage;

  @override
  List<Object?> get props => [documentType, page, perPage];
}

class GetKnowledgeDocumentsUseCase {
  GetKnowledgeDocumentsUseCase(this._repository);

  final CommunicationRepository _repository;

  Future<Result<List<SchoolKnowledgeDocumentEntity>>> call(
    GetKnowledgeDocumentsParams params,
  ) async {
    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page must be >= 1',
          fieldErrors: {'page': 'Invalid page'},
        ),
      );
    }

    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'PerPage must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid perPage'},
        ),
      );
    }

    return _repository.getKnowledgeDocuments(
      documentType: params.documentType,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
