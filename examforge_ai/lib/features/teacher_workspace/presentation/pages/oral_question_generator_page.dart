import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/generate_oral_questions_usecase.dart';
import '../../domain/usecases/create_oral_questions_usecase.dart';
import '../providers/oral_question_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// ORAL QUESTION GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Oral Question Generator page where teachers fill in parameters and AI
/// generates a complete set of oral questions with expected answers, marks,
/// difficulty, and Bloom's taxonomy levels.
///
/// Has two states: input form (no questions generated yet) and generated
/// result (editable question list with expandable cards).
class OralQuestionGeneratorPage extends ConsumerStatefulWidget {
  const OralQuestionGeneratorPage({super.key});

  @override
  ConsumerState<OralQuestionGeneratorPage> createState() =>
      _OralQuestionGeneratorPageState();
}

class _OralQuestionGeneratorPageState
    extends ConsumerState<OralQuestionGeneratorPage> {
  // ─── Form Controllers ────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _customInstructionsCtrl = TextEditingController();

  String? _selectedSubject;
  String? _selectedClass;
  double _questionCount = 10;
  StudentLevel _difficulty = StudentLevel.intermediate;
  CurriculumType _curriculum = CurriculumType.nigerian;

  // ─── Edit State ──────────────────────────────────────────────────────

  final List<GlobalKey<_OralQuestionCardState>> _questionCardKeys = [];
  int? _expandedQuestionIndex;

  static const List<String> _subjects = [
    'Mathematics',
    'English',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'Economics',
    'Literature',
    'Computer Science',
  ];

  static const List<String> _classes = [
    'JSS1',
    'JSS2',
    'JSS3',
    'SS1',
    'SS2',
    'SS3',
    'Primary 4',
    'Primary 5',
    'Primary 6',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    _durationCtrl.dispose();
    _customInstructionsCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  void _listenForMessages() {
    final state = ref.read(oralQuestionProvider);
    if (state.successMessage != null) {
      _showSnackBar(state.successMessage!, isError: false);
      ref.read(oralQuestionProvider.notifier).clearSuccessMessage();
    }
    if (state.error != null) {
      _showSnackBar(state.error!, isError: true);
      ref.read(oralQuestionProvider.notifier).clearError();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    final cs = context.colorScheme;
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(oralQuestionProvider.notifier).generateOralQuestions(
      GenerateOralQuestionsParams(
        subjectId: _selectedSubject,
        topic: _topicCtrl.text.trim(),
        questionCount: _questionCount.round(),
        difficulty: _difficulty.value,
        curriculum: _curriculum.value,
      ),
    );

    _listenForMessages();
  }

  void _handleSaveDraft() {
    _showSnackBar('Oral questions saved as draft', isError: false);
  }

  void _handleSaveAndPublish() {
    _showSnackBar('Oral questions published successfully', isError: false);
  }

  void _handleExport() {
    _showSnackBar('Exporting oral questions as PDF...', isError: false);
  }

  void _handleShare() {
    _showSnackBar('Share dialog opened', isError: false);
  }

  void _handleAddQuestion() {
    final oq = ref.read(oralQuestionProvider).currentOralQuestion;
    if (oq == null) return;

    final newQuestion = OralQuestionItemEntity(
      question: 'New Question',
      expectedAnswer: '',
      marks: 1.0,
      difficulty: _difficulty.label,
      bloomLevel: 'Remember',
    );

    final updated = oq.copyWith(
      questions: [...oq.questions, newQuestion],
    );
    ref.read(oralQuestionProvider.notifier).setCurrentOralQuestion(updated);
    setState(() {});
  }

  void _handleDeleteQuestion(int index) {
    final oq = ref.read(oralQuestionProvider).currentOralQuestion;
    if (oq == null) return;

    final updatedQuestions = List<OralQuestionItemEntity>.from(oq.questions)
      ..removeAt(index);
    final updated = oq.copyWith(questions: updatedQuestions);
    ref.read(oralQuestionProvider.notifier).setCurrentOralQuestion(updated);
    setState(() {});
  }

  void _handleGenerateForCBT() {
    _showSnackBar('Generating questions for CBT...', isError: false);
  }

  void _handleReset() {
    ref.read(oralQuestionProvider.notifier).setCurrentOralQuestion(null);
    _expandedQuestionIndex = null;
    setState(() {});
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(oralQuestionProvider);
    final oralQuestion = state.currentOralQuestion;

    return Scaffold(
      appBar: AppAppBar(
        title:
            oralQuestion != null ? 'Generated Oral Questions' : 'AI Oral Question Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (oralQuestion != null)
            AppIconButton(
              icon: Icons.restart_alt_rounded,
              onPressed: _handleReset,
              tooltip: 'Start Over',
              variant: AppIconButtonVariant.standard,
            ),
        ],
      ),
      body: state.isGenerating
          ? _buildGeneratingState()
          : oralQuestion != null
              ? _buildGeneratedResult(oralQuestion)
              : _buildInputForm(),
    );
  }

  // ─── Input Form ──────────────────────────────────────────────────────

  Widget _buildInputForm() {
    final cs = context.colorScheme;

    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create Oral Questions with AI',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: AppTypography.wBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI generate oral questions with expected answers and marking schemes.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Spacings.sectionGap,

            // Subject dropdown
            _buildDropdownField(
              label: 'Subject',
              hint: 'Select a subject',
              value: _selectedSubject,
              items: _subjects,
              prefixIcon: Icons.book_outlined,
              isRequired: true,
              onChanged: (v) => setState(() => _selectedSubject = v),
            ),
            Spacings.itemGap,

            // Class dropdown
            _buildDropdownField(
              label: 'Class',
              hint: 'Select a class',
              value: _selectedClass,
              items: _classes,
              prefixIcon: Icons.school_outlined,
              onChanged: (v) => setState(() => _selectedClass = v),
            ),
            Spacings.itemGap,

            // Topic
            AppTextField(
              label: 'Topic',
              hint: 'e.g. Photosynthesis, Quadratic Equations',
              controller: _topicCtrl,
              prefixIcon: Icons.topic_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Topic is required' : null,
            ),
            Spacings.itemGap,

            // Number of Questions (Slider)
            _buildSliderField(
              label: 'Number of Questions',
              value: _questionCount,
              min: 5,
              max: 30,
              divisions: 25,
              valueLabel: _questionCount.round().toString(),
            ),
            Spacings.itemGap,

            // Difficulty dropdown
            _buildEnumDropdownField<StudentLevel>(
              label: 'Difficulty',
              value: _difficulty,
              items: StudentLevel.values,
              itemLabel: (s) => s.label,
              prefixIcon: Icons.signal_cellular_alt_rounded,
              onChanged: (v) {
                if (v != null) setState(() => _difficulty = v);
              },
            ),
            Spacings.itemGap,

            // Curriculum dropdown
            _buildEnumDropdownField<CurriculumType>(
              label: 'Curriculum',
              value: _curriculum,
              items: CurriculumType.values,
              itemLabel: (c) => c.label,
              prefixIcon: Icons.school_outlined,
              onChanged: (v) {
                if (v != null) setState(() => _curriculum = v);
              },
            ),
            Spacings.itemGap,

            // Estimated Duration
            AppTextField(
              label: 'Estimated Duration (minutes)',
              hint: 'e.g. 30',
              controller: _durationCtrl,
              prefixIcon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
            Spacings.itemGap,

            // Custom Instructions
            AppTextField(
              label: 'Custom Instructions',
              hint: 'Any specific instructions for the AI question generator...',
              controller: _customInstructionsCtrl,
              prefixIcon: Icons.edit_note_rounded,
              maxLines: 4,
              minLines: 2,
            ),
            Spacings.sectionGap,

            // Generate Button
            AppButton(
              label: 'Generate Oral Questions',
              onPressed: _handleGenerate,
              variant: AppButtonVariant.elevated,
              icon: Icons.auto_awesome,
              isLoading: ref.watch(oralQuestionProvider).isGenerating,
              fullWidth: true,
              size: AppButtonSize.large,
            ),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData prefixIcon,
    bool isRequired = false,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(prefixIcon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label + (isRequired ? ' *' : ''),
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            contentPadding: Spacings.paddingInput,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (v) => v == null ? '$label is required' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildEnumDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required IconData prefixIcon,
    required ValueChanged<T?> onChanged,
  }) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(prefixIcon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            contentPadding: Spacings.paddingInput,
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String valueLabel,
  }) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
              child: Text(
                valueLabel,
                style: context.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: (v) => setState(() => _questionCount = v),
        ),
      ],
    );
  }

  // ─── Generating State ────────────────────────────────────────────────

  Widget _buildGeneratingState() {
    final cs = context.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            const SizedBox(height: Spacings.xl),
            Text(
              'Generating Oral Questions...',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'AI is crafting oral questions with expected answers and marking schemes. This may take a moment.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Generated Result ────────────────────────────────────────────────

  Widget _buildGeneratedResult(OralQuestionEntity oralQuestion) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI badge
          if (oralQuestion.isAiGenerated) _buildAiBadge(),
          const SizedBox(height: Spacings.md),

          // Preview card
          _buildPreviewCard(oralQuestion),
          Spacings.itemGap,

          // Question list
          ...oralQuestion.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.md),
              child: _OralQuestionCard(
                key: ValueKey('question_$index'),
                index: index,
                question: question,
                isExpanded: _expandedQuestionIndex == index,
                onExpand: () => setState(() {
                  _expandedQuestionIndex =
                      _expandedQuestionIndex == index ? null : index;
                }),
                onDelete: () => _handleDeleteQuestion(index),
              ),
            );
          }),

          // Add Question button
          AppButton(
            label: 'Add Question',
            onPressed: _handleAddQuestion,
            variant: AppButtonVariant.tonal,
            icon: Icons.add_rounded,
            size: AppButtonSize.medium,
            fullWidth: true,
          ),
          Spacings.sectionGap,

          // Action buttons
          _buildActionButtons(),
          const SizedBox(height: Spacings.xxl),
        ],
      ),
    );
  }

  Widget _buildAiBadge() {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.onTertiaryContainer),
          const SizedBox(width: Spacings.xs),
          Text(
            'AI Generated',
            style: context.textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(OralQuestionEntity oralQuestion) {
    final cs = context.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  oralQuestion.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.help_outline_rounded,
                label: '${oralQuestion.questions.length} questions',
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              _buildStatChip(
                icon: Icons.star_outline_rounded,
                label: '${oralQuestion.totalMarks.toInt()} marks',
                color: cs.tertiary,
              ),
              if (oralQuestion.estimatedDurationMinutes != null) ...[
                const SizedBox(width: Spacings.sm),
                _buildStatChip(
                  icon: Icons.timer_outlined,
                  label: '${oralQuestion.estimatedDurationMinutes} min',
                  color: cs.secondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Save as Draft',
                onPressed: _handleSaveDraft,
                variant: AppButtonVariant.outlined,
                icon: Icons.save_outlined,
                size: AppButtonSize.medium,
              ),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: AppButton(
                label: 'Save & Publish',
                onPressed: _handleSaveAndPublish,
                variant: AppButtonVariant.elevated,
                icon: Icons.public_rounded,
                size: AppButtonSize.medium,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // Export button
        AppButton(
          label: 'Export as PDF',
          onPressed: _handleExport,
          variant: AppButtonVariant.tonal,
          icon: Icons.picture_as_pdf_outlined,
          size: AppButtonSize.medium,
          fullWidth: true,
        ),
        const SizedBox(height: Spacings.sm),

        // Share button
        AppButton(
          label: 'Share with Colleagues',
          onPressed: _handleShare,
          variant: AppButtonVariant.text,
          icon: Icons.share_rounded,
          size: AppButtonSize.medium,
          fullWidth: true,
        ),
        const SizedBox(height: Spacings.sm),

        // CBT button
        AppButton(
          label: 'Generate Questions for CBT',
          onPressed: _handleGenerateForCBT,
          variant: AppButtonVariant.outlined,
          icon: Icons.computer_rounded,
          size: AppButtonSize.medium,
          fullWidth: true,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ORAL QUESTION CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

/// Expandable card for a single oral question with edit mode.
class _OralQuestionCard extends StatefulWidget {
  const _OralQuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.isExpanded,
    required this.onExpand,
    required this.onDelete,
  });

  final int index;
  final OralQuestionItemEntity question;
  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onDelete;

  @override
  State<_OralQuestionCard> createState() => _OralQuestionCardState();
}

class _OralQuestionCardState extends State<_OralQuestionCard> {
  bool _isEditing = false;
  late TextEditingController _questionCtrl;
  late TextEditingController _answerCtrl;
  late TextEditingController _marksCtrl;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.question.question);
    _answerCtrl =
        TextEditingController(text: widget.question.expectedAnswer ?? '');
    _marksCtrl =
        TextEditingController(text: widget.question.marks.toString());
  }

  @override
  void didUpdateWidget(covariant _OralQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      _questionCtrl.text = widget.question.question;
      _answerCtrl.text = widget.question.expectedAnswer ?? '';
      _marksCtrl.text = widget.question.marks.toString();
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return AppCard(
      onTap: widget.onExpand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  'Q${widget.index + 1}',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  widget.question.question,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Marks badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  '${widget.question.marks.toInt()} marks',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: cs.onTertiaryContainer,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Icon(
                widget.isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),

          // Expanded content
          if (widget.isExpanded) ...[
            const SizedBox(height: Spacings.md),
            const Divider(height: 1),
            const SizedBox(height: Spacings.md),

            // Question text
            if (_isEditing)
              TextFormField(
                controller: _questionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Question Text',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
              )
            else
              _buildDetailRow(
                icon: Icons.help_outline_rounded,
                label: 'Question',
                value: widget.question.question,
              ),
            const SizedBox(height: Spacings.sm),

            // Expected answer
            if (_isEditing)
              TextFormField(
                controller: _answerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Expected Answer',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 4,
              )
            else
              _buildDetailRow(
                icon: Icons.lightbulb_outline_rounded,
                label: 'Expected Answer',
                value: widget.question.expectedAnswer ?? 'N/A',
              ),
            const SizedBox(height: Spacings.sm),

            // Marks, difficulty, Bloom's level row
            if (_isEditing)
              TextFormField(
                controller: _marksCtrl,
                decoration: const InputDecoration(
                  labelText: 'Marks',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              )
            else
              Row(
                children: [
                  if (widget.question.difficulty != null)
                    _buildChip(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: widget.question.difficulty!,
                      color: cs.primary,
                    ),
                  if (widget.question.bloomLevel != null) ...[
                    const SizedBox(width: Spacings.sm),
                    _buildChip(
                      icon: Icons.psychology_outlined,
                      label: widget.question.bloomLevel!,
                      color: cs.secondary,
                    ),
                  ],
                  const SizedBox(width: Spacings.sm),
                  _buildChip(
                    icon: Icons.star_outline_rounded,
                    label: '${widget.question.marks.toInt()} marks',
                    color: cs.tertiary,
                  ),
                ],
              ),

            const SizedBox(height: Spacings.md),

            // Action buttons
            Row(
              children: [
                AppButton(
                  label: _isEditing ? 'Done' : 'Edit',
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                  variant: AppButtonVariant.text,
                  icon: _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                  size: AppButtonSize.small,
                ),
                const Spacer(),
                AppButton(
                  label: 'Delete',
                  onPressed: widget.onDelete,
                  variant: AppButtonVariant.text,
                  icon: Icons.delete_outline_rounded,
                  size: AppButtonSize.small,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.xs),
            Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }
}
