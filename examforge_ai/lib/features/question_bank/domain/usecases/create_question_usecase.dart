import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../entities/question_entities.dart';
import '../repositories/question_bank_repository.dart';

/// Parameters for the [CreateQuestionUseCase].
class CreateQuestionParams {
  const CreateQuestionParams({
    required this.question,
    this.answerOptions = const [],
    this.matchingPairs = const [],
    this.orderingItems = const [],
    this.fillInBlankAnswers = const [],
    this.attachments = const [],
    this.tagIds = const [],
  });

  /// The question entity to create.
  final QuestionEntity question;

  /// Answer options for choice-based questions.
  final List<AnswerOptionEntity> answerOptions;

  /// Matching pairs for matching-type questions.
  final List<MatchingPairEntity> matchingPairs;

  /// Ordering items for ordering-type questions.
  final List<OrderingItemEntity> orderingItems;

  /// Fill-in-the-blank answers for fill-in-blank questions.
  final List<FillInBlankAnswerEntity> fillInBlankAnswers;

  /// Attachments (images, audio, video, documents).
  final List<QuestionAttachmentEntity> attachments;

  /// IDs of existing tags to associate with the question.
  final List<String> tagIds;
}

/// Use case that creates a new question in the question bank.
///
/// Validates that the question has required fields and that the
/// question type is compatible with the provided answer data,
/// then delegates to [QuestionBankRepository.createQuestion].
class CreateQuestionUseCase {
  CreateQuestionUseCase(this._repository);

  final QuestionBankRepository _repository;

  Future<Result<QuestionEntity>> call(CreateQuestionParams params) async {
    // ── Validate core question fields ───────────────────────────────
    if (params.question.content.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Question content is required',
          fieldErrors: {'content': 'Question content cannot be empty'},
        ),
      );
    }

    if (params.question.subjectId.trim().isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Subject is required',
          fieldErrors: {'subjectId': 'Please select a subject'},
        ),
      );
    }

    if (params.question.marks <= 0) {
      return const FailureResult(
        Failure.validation(
          message: 'Marks must be greater than zero',
          fieldErrors: {'marks': 'Assign at least 1 mark to this question'},
        ),
      );
    }

    // ── Validate type-specific answer data ──────────────────────────
    final type = params.question.questionType;

    if (type.hasOptions && params.answerOptions.isEmpty) {
      return FailureResult(
        Failure.validation(
          message: '${type.label} questions require at least one answer option',
          fieldErrors: {'answerOptions': 'Add at least one answer option'},
        ),
      );
    }

    if (type.hasOptions) {
      final hasCorrect = params.answerOptions.any((o) => o.isCorrect);
      if (type.hasCorrectAnswer && !hasCorrect) {
        return const FailureResult(
          Failure.validation(
            message: 'At least one answer option must be marked as correct',
            fieldErrors: {
              'answerOptions': 'Mark the correct answer(s)',
            },
          ),
        );
      }
    }

    if (type == QuestionType.matching && params.matchingPairs.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Matching questions require at least one matching pair',
          fieldErrors: {'matchingPairs': 'Add at least one matching pair'},
        ),
      );
    }

    if (type == QuestionType.ordering && params.orderingItems.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Ordering questions require at least one ordering item',
          fieldErrors: {'orderingItems': 'Add at least one ordering item'},
        ),
      );
    }

    if (type == QuestionType.fillInBlank &&
        params.fillInBlankAnswers.isEmpty) {
      return const FailureResult(
        Failure.validation(
          message: 'Fill-in-the-blank questions require at least one blank answer',
          fieldErrors: {
            'fillInBlankAnswers': 'Define at least one blank answer',
          },
        ),
      );
    }

    // ── Validate individual fill-in-blank entries ───────────────────
    for (final blank in params.fillInBlankAnswers) {
      if (blank.acceptableAnswers.isEmpty) {
        return const FailureResult(
          Failure.validation(
            message: 'Each blank must have at least one acceptable answer',
            fieldErrors: {
              'fillInBlankAnswers':
                  'Provide at least one acceptable answer for each blank',
            },
          ),
        );
      }
    }

    // ── Delegate to repository ──────────────────────────────────────
    return _repository.createQuestion(params.question);
  }
}
