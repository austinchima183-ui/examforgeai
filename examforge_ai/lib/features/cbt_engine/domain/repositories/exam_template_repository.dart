import '../../../../core/utils/result.dart';
import 'entities/cbt_entities.dart';
import 'entities/exam_template_entities.dart';

/// Abstract contract for all exam template operations.
///
/// The domain layer defines this interface so that domain use cases
/// remain decoupled from any specific data source implementation
/// (Supabase, Firebase, mock, etc.).
///
/// Every method returns a [Result] to force callers to handle both
/// success and failure at compile time, avoiding uncaught exceptions
/// across layer boundaries.
///
/// This repository also handles submission receipt operations since
/// receipts are closely tied to the exam template lifecycle — they
/// are generated when exams created from templates are submitted.
abstract class ExamTemplateRepository {
  // ─── Template CRUD ──────────────────────────────────────────────────

  /// Saves an exam configuration as a reusable template.
  ///
  /// Returns the persisted template entity with server-generated
  /// fields (id, timestamps) populated.
  Future<Result<ExamTemplateEntity>> saveAsTemplate(
    ExamTemplateEntity template,
  );

  /// Retrieves a filtered, paginated list of exam templates.
  ///
  /// When [schoolId] is provided, returns templates belonging to that
  /// school plus any public templates. When omitted, returns only
  /// public templates. Supports filtering by [category] and pagination.
  Future<Result<List<ExamTemplateEntity>>> getTemplates({
    String? schoolId,
    TemplateCategory? category,
    int page = 1,
    int perPage = 20,
  });

  /// Retrieves a single exam template by [templateId] with full details
  /// including sections and question selection rules.
  Future<Result<ExamTemplateEntity>> getTemplate(String templateId);

  /// Permanently deletes an exam template by [templateId].
  ///
  /// Only the template creator or an admin may delete a template.
  /// This check is enforced at the data layer.
  Future<Result<void>> deleteTemplate(String templateId);

  // ─── Exam Creation from Template ────────────────────────────────────

  /// Creates a new exam from an existing template.
  ///
  /// The template provides the base configuration. [overrides] allows
  /// customizing specific fields (e.g., 'title', 'startTime', 'endTime',
  /// 'academicSessionId') without modifying the template itself.
  ///
  /// Question selection rules defined in the template are executed to
  /// auto-populate questions from the question bank.
  Future<Result<ExamEntity>> createExamFromTemplate(
    String templateId,
    Map<String, dynamic> overrides,
  );

  // ─── Submission Receipts ────────────────────────────────────────────

  /// Retrieves the submission receipt for a completed exam attempt.
  ///
  /// Returns a receipt containing verifiable submission metadata
  /// including question counts, time spent, and device information.
  Future<Result<SubmissionReceiptEntity>> getSubmissionReceipt(
    String attemptId,
  );

  /// Verifies the authenticity of a submission receipt by its
  /// [receiptNumber].
  ///
  /// Returns `true` if the receipt number corresponds to a valid,
  /// verified submission in the system.
  Future<Result<bool>> verifyReceipt(String receiptNumber);
}
