import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// The type of collection action to perform.
enum CollectionAction {
  create('create'),
  update('update'),
  delete('delete'),
  addQuestion('add_question'),
  removeQuestion('remove_question'),
  getQuestions('get_questions');

  const CollectionAction(this.value);

  /// The string representation stored in the backend.
  final String value;

  /// Parses a raw [value] string into a [CollectionAction].
  ///
  /// Returns `null` if the value does not match any known action.
  static CollectionAction? fromString(String? value) {
    if (value == null) return null;
    return CollectionAction.values.cast<CollectionAction?>().firstWhere(
          (action) => action?.value == value,
          orElse: () => null,
        );
  }
}

/// Parameters for the [ManageCollectionsUseCase].
///
/// Different fields are required depending on [action]:
/// - **create / update**: [collection] is required.
/// - **delete**: [collectionId] is required.
/// - **addQuestion / removeQuestion**: [collectionId] and [questionId]
///   are required.
/// - **getQuestions**: [collectionId] is required; [page] and [perPage]
///   are optional.
class ManageCollectionsParams {
  const ManageCollectionsParams({
    required this.action,
    this.collection,
    this.collectionId,
    this.questionId,
    this.page = 1,
    this.perPage = 20,
  });

  /// The action to perform.
  final CollectionAction action;

  /// The collection entity (required for create and update actions).
  final QuestionCollectionEntity? collection;

  /// The collection ID (required for delete, addQuestion, removeQuestion,
  /// and getQuestions actions).
  final String? collectionId;

  /// The question ID (required for addQuestion and removeQuestion).
  final String? questionId;

  /// Page number for getQuestions (defaults to 1).
  final int page;

  /// Number of items per page for getQuestions (defaults to 20).
  final int perPage;
}

/// Use case that manages question collections through a unified interface.
///
/// Supports CRUD operations on collections and adding/removing questions
/// from collections. Validates that required fields are present based
/// on the requested [CollectionAction], then delegates to the
/// appropriate repository method.
///
/// ```dart
/// // Create a collection
/// final result = await manageCollectionsUseCase(
///   ManageCollectionsParams(
///     action: CollectionAction.create,
///     collection: QuestionCollectionEntity(...),
///   ),
/// );
///
/// // Add a question to a collection
/// final result = await manageCollectionsUseCase(
///   ManageCollectionsParams(
///     action: CollectionAction.addQuestion,
///     collectionId: 'col-123',
///     questionId: 'q-456',
///   ),
/// );
/// ```
class ManageCollectionsUseCase {
  ManageCollectionsUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<dynamic>> call(ManageCollectionsParams params) async {
    switch (params.action) {
      case CollectionAction.create:
        return _handleCreate(params);
      case CollectionAction.update:
        return _handleUpdate(params);
      case CollectionAction.delete:
        return _handleDelete(params);
      case CollectionAction.addQuestion:
        return _handleAddQuestion(params);
      case CollectionAction.removeQuestion:
        return _handleRemoveQuestion(params);
      case CollectionAction.getQuestions:
        return _handleGetQuestions(params);
    }
  }

  // ── Private Handlers ──────────────────────────────────────────────

  Future<Result<QuestionCollectionEntity>> _handleCreate(
    ManageCollectionsParams params,
  ) async {
    if (params.collection == null) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection data is required for creation',
          fieldErrors: {'collection': 'Provide collection details'},
        ),
      );
    }

    if (params.collection!.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection name is required',
          fieldErrors: {'name': 'Enter a name for the collection'},
        ),
      );
    }

    return _repository.createCollection(params.collection!);
  }

  Future<Result<QuestionCollectionEntity>> _handleUpdate(
    ManageCollectionsParams params,
  ) async {
    if (params.collection == null) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection data is required for update',
          fieldErrors: {'collection': 'Provide collection details'},
        ),
      );
    }

    if (params.collection!.id.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection ID is required for update',
          fieldErrors: {'id': 'Cannot update a collection without an ID'},
        ),
      );
    }

    if (params.collection!.name.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection name is required',
          fieldErrors: {'name': 'Collection name cannot be empty'},
        ),
      );
    }

    return _repository.updateCollection(params.collection!);
  }

  Future<Result<void>> _handleDelete(
    ManageCollectionsParams params,
  ) async {
    if (params.collectionId == null || params.collectionId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection ID is required for deletion',
          fieldErrors: {'collectionId': 'Provide the collection to delete'},
        ),
      );
    }

    return _repository.deleteCollection(params.collectionId!);
  }

  Future<Result<void>> _handleAddQuestion(
    ManageCollectionsParams params,
  ) async {
    if (params.collectionId == null || params.collectionId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection ID is required',
          fieldErrors: {'collectionId': 'Select a collection'},
        ),
      );
    }

    if (params.questionId == null || params.questionId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Select a question to add'},
        ),
      );
    }

    return _repository.addQuestionToCollection(
      params.collectionId!,
      params.questionId!,
    );
  }

  Future<Result<void>> _handleRemoveQuestion(
    ManageCollectionsParams params,
  ) async {
    if (params.collectionId == null || params.collectionId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection ID is required',
          fieldErrors: {'collectionId': 'Select a collection'},
        ),
      );
    }

    if (params.questionId == null || params.questionId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question ID is required',
          fieldErrors: {'questionId': 'Select a question to remove'},
        ),
      );
    }

    return _repository.removeQuestionFromCollection(
      params.collectionId!,
      params.questionId!,
    );
  }

  Future<Result<List<QuestionEntity>>> _handleGetQuestions(
    ManageCollectionsParams params,
  ) async {
    if (params.collectionId == null || params.collectionId!.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Collection ID is required',
          fieldErrors: {'collectionId': 'Select a collection'},
        ),
      );
    }

    if (params.page < 1) {
      return const FailureResult(
        Failure.validation(
          message: 'Page number must be at least 1',
          fieldErrors: {'page': 'Invalid page number'},
        ),
      );
    }

    if (params.perPage < 1 || params.perPage > 100) {
      return const FailureResult(
        Failure.validation(
          message: 'Per-page count must be between 1 and 100',
          fieldErrors: {'perPage': 'Invalid per-page count'},
        ),
      );
    }

    return _repository.getCollectionQuestions(
      params.collectionId!,
      page: params.page,
      perPage: params.perPage,
    );
  }
}
