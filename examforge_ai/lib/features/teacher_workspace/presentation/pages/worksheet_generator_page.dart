import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_worksheet_usecase.dart';
import '../../domain/usecases/export_worksheet_usecase.dart';
import '../../domain/usecases/generate_worksheet_usecase.dart';
import '../providers/worksheet_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// WORKSHEET GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI-powered Worksheet Generator page.
///
/// Teachers specify subject, class, topic, worksheet type, difficulty,
/// and question count; the AI generates a complete worksheet with
/// questions, answer key, total marks, and duration.
class WorksheetGeneratorPage extends ConsumerStatefulWidget {
  const WorksheetGeneratorPage({super.key});

  @override
  ConsumerState<WorksheetGeneratorPage> createState() =>
      _WorksheetGeneratorPageState();
}

class _WorksheetGeneratorPageState
    extends ConsumerState<WorksheetGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _classNameController = TextEditingController();
  final _topicController = TextEditingController();
  final _questionCountController = TextEditingController(text: '10');

  WorksheetType _worksheetType = WorksheetType.classwork;
  String _difficulty = 'medium';
  bool _answerKeyExpanded = false;
  bool _showResult = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _classNameController.dispose();
    _topicController.dispose();
    _questionCountController.dispose();
    super.dispose();
  }

  // ─── Form Validation ──────────────────────────────────────────────

  bool get _isFormValid {
    return _subjectController.text.trim().isNotEmpty;
  }

  // ─── Generate Worksheet ───────────────────────────────────────────

  void _generateWorksheet() {
    if (!_formKey.currentState!.validate()) return;

    final questionCount = int.tryParse(_questionCountController.text.trim()) ?? 10;

    ref.read(worksheetProvider.notifier).generateWorksheet(
          GenerateWorksheetParams(
            subject: _subjectController.text.trim(),
            className: _classNameController.text.trim().isNotEmpty
                ? _classNameController.text.trim()
                : null,
            topic: _topicController.text.trim().isNotEmpty
                ? _topicController.text.trim()
                : null,
            worksheetType: _worksheetType,
            difficulty: _difficulty,
            questionCount: questionCount,
          ),
        );
    setState(() => _showResult = true);
  }

  // ─── Save Worksheet ───────────────────────────────────────────────

  void _saveWorksheet() {
    final worksheet = ref.read(worksheetProvider).currentWorksheet;
    if (worksheet == null) return;

    ref.read(worksheetProvider.notifier).createWorksheet(
          CreateWorksheetParams(worksheet: worksheet),
        );
  }

  // ─── Export Worksheet ─────────────────────────────────────────────

  void _exportWorksheet(String format) {
    final worksheet = ref.read(worksheetProvider).currentWorksheet;
    if (worksheet == null) return;

    ref.read(worksheetProvider.notifier).exportWorksheet(
          ExportWorksheetParams(
            worksheetId: worksheet.id,
            format: format,
          ),
        );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(worksheetProvider);

    ref.listen<WorksheetState>(worksheetProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: cs.error),
        );
        ref.read(worksheetProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.successMessage!), backgroundColor: cs.primary,),
        );
        ref.read(worksheetProvider.notifier).clearSuccessMessage();
      }
    });

    return Scaffold(
      appBar: const AppAppBar(
        title: 'AI Worksheet',
      ),
      body: state.isGenerating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
                  const SizedBox(height: Spacings.lg),
                  Text(
                    'Generating worksheet...',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'This may take a moment',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: Spacings.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Input Form ─────────────────────────────────────
                  if (!_showResult || state.currentWorksheet == null) ...[
                    _buildFormSection(cs, tt, state),
                  ],

                  // ── Generated Result ──────────────────────────────
                  if (_showResult && state.currentWorksheet != null) ...[
                    _buildResultHeader(cs, tt, state.currentWorksheet!),
                    const SizedBox(height: Spacings.lg),
                    _buildInstructions(cs, tt, state.currentWorksheet!),
                    const SizedBox(height: Spacings.lg),
                    _buildQuestionsList(cs, tt, state.currentWorksheet!),
                    const SizedBox(height: Spacings.lg),
                    _buildAnswerKey(cs, tt, state.currentWorksheet!),
                    const SizedBox(height: Spacings.lg),
                    _buildMarksAndDuration(cs, tt, state.currentWorksheet!),
                    const SizedBox(height: Spacings.xl),
                    _buildActionButtons(cs, state),
                  ],
                ],
              ),
            ),
    );
  }

  // ─── Form Section ─────────────────────────────────────────────────

  Widget _buildFormSection(
      ColorScheme cs, TextTheme tt, WorksheetState state,) {
    return Form(
      key: _formKey,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary, size: Spacings.lgIcon),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Generate with AI',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI create a complete worksheet for you.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Spacings.xl),

            // Subject (required)
            AppTextField(
              label: 'Subject',
              hint: 'e.g. Mathematics',
              controller: _subjectController,
              prefixIcon: Icons.book_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Subject is required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacings.lg),

            // Class Name
            AppTextField(
              label: 'Class Name',
              hint: 'e.g. SS2, JSS3',
              controller: _classNameController,
              prefixIcon: Icons.school_outlined,
            ),
            const SizedBox(height: Spacings.lg),

            // Topic
            AppTextField(
              label: 'Topic',
              hint: 'e.g. Quadratic Equations',
              controller: _topicController,
              prefixIcon: Icons.topic_outlined,
            ),
            const SizedBox(height: Spacings.lg),

            // Worksheet Type Dropdown
            AppDropdownField<WorksheetType>(
              label: 'Worksheet Type',
              items: WorksheetType.values,
              selectedItem: _worksheetType,
              onChanged: (v) {
                if (v != null) setState(() => _worksheetType = v);
              },
              itemLabel: (t) => t.label,
              prefixIcon: Icons.description_outlined,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.lg),

            // Difficulty Dropdown
            AppDropdownField<String>(
              label: 'Difficulty',
              items: const ['easy', 'medium', 'hard'],
              selectedItem: _difficulty,
              onChanged: (v) {
                if (v != null) setState(() => _difficulty = v);
              },
              itemLabel: (d) => d[0].toUpperCase() + d.substring(1),
              prefixIcon: Icons.signal_cellular_alt_outlined,
            ),
            const SizedBox(height: Spacings.lg),

            // Number of Questions
            AppTextField(
              label: 'Number of Questions',
              hint: '10',
              controller: _questionCountController,
              prefixIcon: Icons.format_list_numbered_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Spacings.xxl),

            // Generate Button
            AppButton(
              label: 'Generate Worksheet',
              onPressed: _isFormValid ? _generateWorksheet : null,
              variant: AppButtonVariant.elevated,
              fullWidth: true,
              icon: Icons.auto_awesome,
              isLoading: state.isGenerating,
              isDisabled: !_isFormValid || state.isBusy,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Header ────────────────────────────────────────────────

  Widget _buildResultHeader(
      ColorScheme cs, TextTheme tt, WorksheetEntity worksheet,) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & AI badge
          Row(
            children: [
              Expanded(
                child: Text(
                  worksheet.title,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (worksheet.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: Spacings.smIcon, color: cs.onTertiaryContainer,),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'AI Generated',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Metadata chips
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              _buildMetadataChip(cs, tt, Icons.book_outlined, worksheet.subject),
              if (worksheet.className != null)
                _buildMetadataChip(
                    cs, tt, Icons.school_outlined, worksheet.className!,),
              _buildMetadataChip(cs, tt, Icons.description_outlined,
                  worksheet.worksheetType.label,),
              _buildMetadataChip(
                cs,
                tt,
                Icons.signal_cellular_alt_outlined,
                worksheet.difficulty[0].toUpperCase() +
                    worksheet.difficulty.substring(1),
              ),
              if (worksheet.topic != null)
                _buildMetadataChip(
                    cs, tt, Icons.topic_outlined, worksheet.topic!,),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Version indicator
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant,),
              const SizedBox(width: Spacings.xs),
              Text(
                'Version ${worksheet.version}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(
      ColorScheme cs, TextTheme tt, IconData icon, String label,) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Instructions ─────────────────────────────────────────────────

  Widget _buildInstructions(
      ColorScheme cs, TextTheme tt, WorksheetEntity worksheet,) {
    if (worksheet.instructions == null ||
        worksheet.instructions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Instructions',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            worksheet.instructions!,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ─── Questions List ───────────────────────────────────────────────

  Widget _buildQuestionsList(
      ColorScheme cs, TextTheme tt, WorksheetEntity worksheet,) {
    final questions = worksheet.questions;
    if (questions.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Text(
              'No questions generated yet.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions (${questions.length})',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: _buildQuestionCard(cs, tt, index + 1, question),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionCard(
      ColorScheme cs, TextTheme tt, int number, Map<String, dynamic> question,) {
    final text = question['text'] as String? ?? question['question'] as String? ?? '';
    final type = question['type'] as String? ?? '';
    final marks = question['marks'] ?? question['mark'] ?? '';
    final options = question['options'] as List<dynamic>?;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: AppTypography.wBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  text,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                ),
              ),
              if (marks != '') ...[
                const SizedBox(width: Spacings.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    '$marks mark${marks == 1 ? '' : 's'}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Options (for MCQ type)
          if (options != null && options.isNotEmpty) ...[
            const SizedBox(height: Spacings.sm),
            ...options.map((option) {
              final optionText = option.toString();
              return Padding(
                padding: const EdgeInsets.only(
                  left: Spacings.xl,
                  bottom: Spacings.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u2022 ',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        optionText,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── Answer Key (Collapsible) ─────────────────────────────────────

  Widget _buildAnswerKey(
      ColorScheme cs, TextTheme tt, WorksheetEntity worksheet,) {
    final answers = worksheet.answerKey;
    if (answers.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _answerKeyExpanded = !_answerKeyExpanded),
            child: Row(
              children: [
                Icon(Icons.key_outlined,
                    size: Spacings.mdIcon, color: cs.primary,),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Answer Key',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  _answerKeyExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_answerKeyExpanded) ...[
            const SizedBox(height: Spacings.md),
            const Divider(),
            const SizedBox(height: Spacings.sm),
            ...answers.asMap().entries.map((entry) {
              final index = entry.key;
              final answer = entry.value;
              final questionNum =
                  answer['questionNumber'] ?? answer['number'] ?? (index + 1);
              final answerText =
                  answer['answer'] as String? ?? answer.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$questionNum.',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        answerText,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── Total Marks & Duration ───────────────────────────────────────

  Widget _buildMarksAndDuration(
      ColorScheme cs, TextTheme tt, WorksheetEntity worksheet,) {
    return Row(
      children: [
        // Total marks
        Expanded(
          child: AppCard(
            child: Column(
              children: [
                Icon(Icons.grade_outlined,
                    size: Spacings.lgIcon, color: cs.primary,),
                const SizedBox(height: Spacings.sm),
                Text(
                  'Total Marks',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  '${worksheet.totalMarks.toInt()}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Spacings.md),

        // Duration
        if (worksheet.durationMinutes != null)
          Expanded(
            child: AppCard(
              child: Column(
                children: [
                  Icon(Icons.timer_outlined,
                      size: Spacings.lgIcon, color: cs.tertiary,),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'Duration',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '${worksheet.durationMinutes} min',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────

  Widget _buildActionButtons(ColorScheme cs, WorksheetState state) {
    final worksheet = state.currentWorksheet;
    return Wrap(
      spacing: Spacings.md,
      runSpacing: Spacings.sm,
      alignment: WrapAlignment.start,
      children: [
        // Save
        AppButton(
          label: 'Save',
          onPressed: state.isCreating ? null : _saveWorksheet,
          variant: AppButtonVariant.elevated,
          icon: Icons.save_outlined,
          isLoading: state.isCreating,
        ),

        // Export dropdown
        PopupMenuButton<String>(
          onSelected: _exportWorksheet,
          enabled: !state.isExporting,
          position: PopupMenuPosition.under,
          child: AppButton(
            label: 'Export',
            onPressed: null, // handled by popup
            variant: AppButtonVariant.outlined,
            icon: state.isExporting
                ? null
                : Icons.file_download_outlined,
            isLoading: state.isExporting,
          ),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
            const PopupMenuItem(value: 'docx', child: Text('Export as DOCX')),
          ],
        ),

        // Generate Questions
        if (worksheet != null)
          GenerateQuestionsButton(
            resourceType: 'worksheet',
            resourceId: worksheet.id,
            resourceName: worksheet.title,
          ),

        // New / Reset
        AppButton(
          label: 'New',
          onPressed: () {
            setState(() {
              _showResult = false;
              _subjectController.clear();
              _classNameController.clear();
              _topicController.clear();
              _questionCountController.text = '10';
              _worksheetType = WorksheetType.classwork;
              _difficulty = 'medium';
            });
          },
          variant: AppButtonVariant.outlined,
          icon: Icons.add_rounded,
        ),
      ],
    );
  }
}
