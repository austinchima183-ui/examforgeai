import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/cbt_models.dart';
import '../models/exam_template_models.dart';

// ═══════════════════════════════════════════════════════════════════════
// ABSTRACT INTERFACE
// ═══════════════════════════════════════════════════════════════════════

/// Abstract interface for all remote exam template data operations.
///
/// Implementations handle all network communication with the Supabase
/// backend and return plain model instances. Exceptions are allowed to
/// propagate so the repository layer can catch and convert them to
/// domain [Failure] types.
abstract class ExamTemplateRemoteDataSource {
  // ─── Template CRUD ──────────────────────────────────────────────────

  /// Saves an exam configuration as a reusable template.
  Future<ExamTemplateModel> saveAsTemplate(Map<String, dynamic> templateData);

  /// Retrieves a filtered, paginated list of exam templates.
  Future<List<ExamTemplateModel>> getTemplates(Map<String, dynamic> filters);

  /// Retrieves a single exam template by [templateId] with full details.
  Future<ExamTemplateModel> getTemplate(String templateId);

  /// Permanently deletes an exam template by [templateId].
  Future<void> deleteTemplate(String templateId);

  // ─── Exam Creation from Template ────────────────────────────────────

  /// Creates a new exam from an existing template.
  Future<ExamModel> createExamFromTemplate(
    String templateId,
    Map<String, dynamic> overrides,
  );

  // ─── Submission Receipts ────────────────────────────────────────────

  /// Retrieves the submission receipt for a completed exam attempt.
  Future<SubmissionReceiptModel> getSubmissionReceipt(String attemptId);

  /// Verifies the authenticity of a receipt by its receipt number.
  Future<bool> verifyReceipt(String receiptNumber);
}

// ═══════════════════════════════════════════════════════════════════════
// SUPABASE IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════

class ExamTemplateRemoteDataSourceImpl
    implements ExamTemplateRemoteDataSource {
  ExamTemplateRemoteDataSourceImpl({
    required sb.SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;

  final sb.SupabaseClient _supabase;

  // ─── Table names ────────────────────────────────────────────────────

  static const _templatesTable = 'exam_templates';
  static const _templateSectionsTable = 'exam_template_sections';
  static const _selectionRulesTable = 'question_selection_rules';
  static const _submissionReceiptsTable = 'submission_receipts';
  static const _examsTable = 'exams';

  // ═══════════════════════════════════════════════════════════════════
  // Template CRUD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ExamTemplateModel> saveAsTemplate(
    Map<String, dynamic> templateData,
  ) async {
    try {
      // Extract nested sections and selection rules so we can insert
      // them as separate rows after the main template is created.
      final sectionsData =
          templateData.remove('sections') as List<dynamic>?;
      final rulesData =
          templateData.remove('question_selection_rules') as List<dynamic>?;

      final response = await _supabase
          .from(_templatesTable)
          .insert(templateData)
          .select()
          .single();

      final templateId = response['id'] as String;

      // Insert sections with the generated template_id.
      if (sectionsData != null && sectionsData.isNotEmpty) {
        final sections = sectionsData
            .whereType<Map<String, dynamic>>()
            .map((s) => {
                  ...s,
                  'template_id': templateId,
                },)
            .toList();
        await _supabase
            .from(_templateSectionsTable)
            .insert(sections);
      }

      // Insert question selection rules with the generated template_id.
      if (rulesData != null && rulesData.isNotEmpty) {
        final rules = rulesData
            .whereType<Map<String, dynamic>>()
            .map((r) => {
                  ...r,
                  'template_id': templateId,
                },)
            .toList();
        await _supabase
            .from(_selectionRulesTable)
            .insert(rules);
      }

      // Re-fetch the template with nested relations to return the
      // complete object.
      return getTemplate(templateId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Save as template failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Save as template unexpected error', error: e);
      throw ServerException(
        message: 'Failed to save as template: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExamTemplateModel>> getTemplates(
    Map<String, dynamic> filters,
  ) async {
    try {
      var filterQuery = _supabase
          .from(_templatesTable)
          .select('*, exam_template_sections(*)');

      // Filter by school_id — return school templates + public templates.
      if (filters['school_id'] != null) {
        filterQuery = filterQuery.or(
          'school_id.eq.${filters['school_id']},is_public.eq.true',
        );
      } else {
        // When no school is specified, only return public templates.
        filterQuery = filterQuery.eq('is_public', true);
      }

      // Filter by category.
      if (filters['category'] != null) {
        filterQuery = filterQuery.eq('category', filters['category'] as String);
      }

      // Filter by subject.
      if (filters['subject_id'] != null) {
        filterQuery = filterQuery.eq('subject_id', filters['subject_id'] as String);
      }

      // Filter by created_by.
      if (filters['created_by'] != null) {
        filterQuery = filterQuery.eq('created_by', filters['created_by'] as String);
      }

      // Pagination.
      final page = filters['page'] as int? ?? 1;
      final perPage =
          filters['per_page'] as int? ?? filters['perPage'] as int? ?? 20;
      final offset = (page - 1) * perPage;

      final transformQuery = filterQuery.order('created_at', ascending: false).range(offset, offset + perPage - 1);

      final response = await transformQuery;

      return response
          .map<ExamTemplateModel>(
            (json) => ExamTemplateModel.fromJson(json),
          )
          .toList();
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get templates failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get templates unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get templates: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExamTemplateModel> getTemplate(String templateId) async {
    try {
      final response = await _supabase
          .from(_templatesTable)
          .select('''
            *,
            exam_template_sections(
              *,
              question_selection_rule:question_selection_rules(*)
            ),
            question_selection_rules(*)
          ''')
          .eq('id', templateId)
          .single();

      return ExamTemplateModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get template failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Template not found: $templateId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get template unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get template: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteTemplate(String templateId) async {
    try {
      // Delete dependent rows first (order matters due to FK constraints).
      await _supabase
          .from(_selectionRulesTable)
          .delete()
          .eq('template_id', templateId);

      await _supabase
          .from(_templateSectionsTable)
          .delete()
          .eq('template_id', templateId);

      await _supabase
          .from(_templatesTable)
          .delete()
          .eq('id', templateId);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete template failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Template not found: $templateId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Delete template unexpected error', error: e);
      throw ServerException(
        message: 'Failed to delete template: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Exam Creation from Template
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<ExamModel> createExamFromTemplate(
    String templateId,
    Map<String, dynamic> overrides,
  ) async {
    try {
      // Fetch the full template including sections and rules.
      final template = await getTemplate(templateId);

      // Build the exam payload from the template, allowing overrides.
      final examData = <String, dynamic>{
        'school_id': template.schoolId,
        'created_by': template.createdBy,
        'title': overrides['title'] ?? template.name,
        'description': overrides['description'] ?? template.description,
        'subject_id': template.subjectId,
        'class_id': template.classId,
        'academic_session_id':
            overrides['academic_session_id'] ?? overrides['academicSessionId'],
        'exam_type': template.examType,
        'status': 'draft',
        'start_time': overrides['start_time'] ?? overrides['startTime'],
        'end_time': overrides['end_time'] ?? overrides['endTime'],
        'time_limit_minutes': template.timeLimitMinutes,
        'total_marks': 0, // will be calculated after questions are added
        'pass_mark': template.passMark,
        'pass_mark_type': template.passMarkType,
        'instructions': template.instructions,
        'allowed_attempts': template.allowedAttempts,
        'negative_marking_enabled': template.negativeMarkingEnabled,
        'negative_mark_value': template.negativeMarkValue,
        'grace_period_minutes': template.gracePeriodMinutes,
        'auto_submit': template.autoSubmit,
        'randomize_questions': template.randomizeQuestions,
        'randomize_options': template.randomizeOptions,
        'show_results': template.showResults,
        'show_correct_answers': template.showCorrectAnswers,
        'show_explanations': template.showExplanations,
        'is_template': false,
        'template_id': templateId,
        'require_full_screen': template.requireFullScreen,
        'allow_resume': template.allowResume,
        'browser_lockdown': template.browserLockdown,
        'metadata': template.metadata,
      };

      // Insert the exam.
      final examResponse = await _supabase
          .from(_examsTable)
          .insert(examData)
          .select()
          .single();

      final examId = examResponse['id'] as String;

      // Insert sections derived from the template sections.
      for (final section in template.sections) {
        final sectionData = <String, dynamic>{
          'exam_id': examId,
          'title': section.title,
          'description': section.description,
          'instructions': section.instructions,
          'sort_order': section.sortOrder,
          'time_limit_minutes': section.timeLimitMinutes,
          'randomize_questions': section.randomizeQuestions,
        };
        await _supabase
            .from('exam_sections')
            .insert(sectionData);
      }

      // Increment template usage count.
      await _supabase
          .from(_templatesTable)
          .update({
            'usage_count': template.usageCount + 1,
          })
          .eq('id', templateId);

      // Return the created exam.
      final exam = ExamModel.fromJson(examResponse);
      return exam;
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Create exam from template failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(message: 'Template not found: $templateId');
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      if (e is ServerException || e is NotFoundException) rethrow;
      AppLogger.error('Create exam from template unexpected error', error: e);
      throw ServerException(
        message: 'Failed to create exam from template: $e',
        statusCode: 500,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Submission Receipts
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<SubmissionReceiptModel> getSubmissionReceipt(
    String attemptId,
  ) async {
    try {
      final response = await _supabase
          .from(_submissionReceiptsTable)
          .select()
          .eq('attempt_id', attemptId)
          .single();

      return SubmissionReceiptModel.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Get submission receipt failed', error: e);
      if (e.code == 'PGRST116') {
        throw NotFoundException(
          message: 'Submission receipt not found for attempt: $attemptId',
        );
      }
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Get submission receipt unexpected error', error: e);
      throw ServerException(
        message: 'Failed to get submission receipt: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> verifyReceipt(String receiptNumber) async {
    try {
      final response = await _supabase
          .from(_submissionReceiptsTable)
          .select('id, is_verified')
          .eq('receipt_number', receiptNumber)
          .maybeSingle();

      if (response == null) return false;
      return response['is_verified'] as bool? ?? false;
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Verify receipt failed', error: e);
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.code ?? '') ?? 500,
        data: e.details,
      );
    } catch (e) {
      AppLogger.error('Verify receipt unexpected error', error: e);
      throw ServerException(
        message: 'Failed to verify receipt: $e',
        statusCode: 500,
      );
    }
  }
}
