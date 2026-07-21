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
import '../../../../shared/widgets/app_error_state.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/generate_assignment_usecase.dart';
import '../../domain/usecases/create_assignment_usecase.dart';
import '../providers/assignment_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Assignment Generator page. Teachers input criteria and receive an
/// AI-generated assignment with title, instructions, questions, and a
/// marking rubric.
class AssignmentGeneratorPage extends ConsumerStatefulWidget {
  const AssignmentGeneratorPage({super.key});

  @override
  ConsumerState<AssignmentGeneratorPage> createState() =>
      _AssignmentGeneratorPageState();
}

class _AssignmentGeneratorPageState
    extends ConsumerState<AssignmentGeneratorPage> {
  // ─── Form Controllers ─────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _classNameController = TextEditingController();
  final _topicController = TextEditingController();
  final _totalMarksController = TextEditingController(text: '100');

  String _selectedDifficulty = 'medium';
  DateTime? _selectedDeadline;
  bool _isRubricExpanded = false;

  static const _difficultyOptions = [
    'easy',
    'medium',
    'hard',
    'mixed',
  ];

  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _subjectController.dispose();
    _classNameController.dispose();
    _topicController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.lgRadius),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _generateAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    final totalMarks = int.tryParse(_totalMarksController.text) ?? 100;

    await ref.read(assignmentProvider.notifier).generateAssignment(
          GenerateAssignmentParams(
            subject: _subjectController.text.trim(),
            className: _classNameController.text.trim().isEmpty
                ? null
                : _classNameController.text.trim(),
            topic: _topicController.text.trim().isEmpty
                ? null
                : _topicController.text.trim(),
            difficulty: _selectedDifficulty,
            totalMarks: totalMarks,
            deadline: _selectedDeadline,
          ),
        );
  }

  Future<void> _saveAssignment() async {
    final state = ref.read(assignmentProvider);
    final assignment = state.currentAssignment;
    if (assignment == null) return;

    await ref.read(assignmentProvider.notifier).createAssignment(
          CreateAssignmentParams(assignment: assignment),
        );

    if (!mounted) return;
    final newState = ref.read(assignmentProvider);
    if (newState.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.successMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(assignmentProvider.notifier).clearSuccessMessage();
    }
  }

  Future<void> _publishAssignment() async {
    final state = ref.read(assignmentProvider);
    final assignment = state.currentAssignment;
    if (assignment == null) return;

    // Save first if not yet saved, then publish
    await ref.read(assignmentProvider.notifier).publishAssignment(assignment.id);

    if (!mounted) return;
    final newState = ref.read(assignmentProvider);
    if (newState.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState.successMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(assignmentProvider.notifier).clearSuccessMessage();
    }
  }

  // ─── Formatting Helper ────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(assignmentProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Assignment Generator',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Input Form Section ───────────────────────────────────
              _buildFormHeader(context),
              Spacings.sectionGap,

              AppTextField(
                label: 'Subject',
                hint: 'e.g. Mathematics',
                controller: _subjectController,
                prefixIcon: Icons.book_outlined,
                isRequired: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Subject is required' : null,
              ),
              Spacings.itemGap,

              AppTextField(
                label: 'Class Name',
                hint: 'e.g. JSS 2A',
                controller: _classNameController,
                prefixIcon: Icons.class_outlined,
              ),
              Spacings.itemGap,

              AppTextField(
                label: 'Topic',
                hint: 'e.g. Quadratic Equations',
                controller: _topicController,
                prefixIcon: Icons.topic_outlined,
              ),
              Spacings.itemGap,

              // Difficulty dropdown
              _buildDifficultyDropdown(context),
              Spacings.itemGap,

              // Total marks
              AppTextField(
                label: 'Total Marks',
                hint: '100',
                controller: _totalMarksController,
                prefixIcon: Icons.score_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              Spacings.itemGap,

              // Deadline picker
              _buildDeadlineField(context),
              Spacings.sectionGap,

              // Generate button
              AppButton(
                label: 'Generate Assignment',
                onPressed: _generateAssignment,
                variant: AppButtonVariant.elevated,
                icon: Icons.auto_awesome_rounded,
                fullWidth: true,
                isLoading: state.isGenerating,
                isDisabled: state.isGenerating,
              ),

              // ── Error Display ────────────────────────────────────────
              if (state.error != null) ...[
                Spacings.itemGap,
                AppErrorState.genericError(
                  message: state.error,
                  onRetry: _generateAssignment,
                ),
              ],

              // ── Generated Result Section ─────────────────────────────
              if (state.currentAssignment != null) ...[
                Spacings.sectionGap,
                _buildDivider(context),
                Spacings.sectionGap,
                _buildGeneratedResult(context, state.currentAssignment!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-Builders ─────────────────────────────────────────────────────

  Widget _buildFormHeader(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.md),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          child: Icon(
            Icons.assignment_rounded,
            size: Spacings.lgIcon,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create with AI',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                'Fill in the details and let AI generate your assignment',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyDropdown(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final effectiveLabel = 'Difficulty *';

    return DropdownButtonFormField<String>(
      value: _selectedDifficulty,
      items: _difficultyOptions
          .map((d) => DropdownMenuItem<String>(
                value: d,
                child: Text(
                  d[0].toUpperCase() + d.substring(1),
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                ),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _selectedDifficulty = v);
      },
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
      decoration: InputDecoration(
        labelText: effectiveLabel,
        prefixIcon: Icon(Icons.signal_cellular_alt_rounded, size: Spacings.mdIcon),
      ),
      dropdownColor: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      menuMaxHeight: 300,
    );
  }

  Widget _buildDeadlineField(BuildContext context) {
    final cs = context.colorScheme;
    final displayText =
        _selectedDeadline != null ? _formatDate(_selectedDeadline!) : null;

    return GestureDetector(
      onTap: _pickDeadline,
      child: AbsorbPointer(
        child: AppTextField(
          label: 'Deadline',
          hint: 'Select a date',
          controller: displayText != null
              ? TextEditingController(text: displayText)
              : null,
          prefixIcon: Icons.calendar_today_outlined,
          suffixIcon: Icon(
            Icons.arrow_drop_down_rounded,
            color: cs.onSurfaceVariant,
          ),
          readOnly: true,
          onTap: _pickDeadline,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: context.colorScheme.outlineVariant.withOpacity(0.5),
      thickness: 1,
    );
  }

  Widget _buildGeneratedResult(
    BuildContext context,
    WorkspaceAssignmentEntity assignment,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(assignmentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── AI Badge ─────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: Spacings.mdIcon, color: cs.tertiary),
            const SizedBox(width: Spacings.sm),
            Text(
              'AI Generated',
              style: tt.labelMedium?.copyWith(
                color: cs.tertiary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // ── Title ────────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.title,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              if (assignment.instructions != null &&
                  assignment.instructions!.isNotEmpty) ...[
                const SizedBox(height: Spacings.md),
                Text(
                  'Instructions',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  assignment.instructions!,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: Spacings.md),
              Wrap(
                spacing: Spacings.md,
                runSpacing: Spacings.sm,
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.book_outlined,
                    label: assignment.subject,
                  ),
                  if (assignment.className != null)
                    _buildInfoChip(
                      context,
                      icon: Icons.class_outlined,
                      label: assignment.className!,
                    ),
                  _buildInfoChip(
                    context,
                    icon: Icons.score_outlined,
                    label: '${assignment.totalMarks.toInt()} marks',
                  ),
                  _buildInfoChip(
                    context,
                    icon: Icons.signal_cellular_alt_rounded,
                    label: assignment.difficulty[0].toUpperCase() +
                        assignment.difficulty.substring(1),
                  ),
                ],
              ),
            ],
          ),
        ),
        Spacings.itemGap,

        // ── Questions List ───────────────────────────────────────────
        if (assignment.questions.isNotEmpty) ...[
          Text(
            'Questions',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          ...assignment.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['text'] as String? ?? '',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: Spacings.xs),
                          Text(
                            '${question['marks'] ?? 0} marks',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // ── Marking Rubric (Collapsible) ─────────────────────────────
        if (assignment.markingRubric.isNotEmpty) ...[
          const SizedBox(height: Spacings.md),
          _buildCollapsibleRubric(context, assignment.markingRubric),
        ],

        Spacings.sectionGap,

        // ── Action Buttons ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Save',
                onPressed: _saveAssignment,
                variant: AppButtonVariant.outlined,
                icon: Icons.save_outlined,
                isLoading: state.isCreating,
                isDisabled: state.isCreating,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: AppButton(
                label: 'Publish to Students',
                onPressed: _publishAssignment,
                variant: AppButtonVariant.elevated,
                icon: Icons.publish_rounded,
                isLoading: state.isPublishing,
                isDisabled: state.isPublishing,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // Generate Questions button
        GenerateQuestionsButton(
          resourceType: 'assignment',
          resourceId: assignment.id,
          difficulty: assignment.difficulty,
          fullWidth: true,
          variant: AppButtonVariant.tonal,
          size: AppButtonSize.medium,
        ),
      ],
    );
  }

  Widget _buildCollapsibleRubric(
    BuildContext context,
    List<Map<String, dynamic>> rubric,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(
          'Marking Rubric',
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        initiallyExpanded: _isRubricExpanded,
        onExpansionChanged: (v) => setState(() => _isRubricExpanded = v),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          Spacings.lg,
          0,
          Spacings.lg,
          Spacings.lg,
        ),
        children: rubric.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: Spacings.mdIcon,
                  color: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['criterion'] as String? ?? '',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wMedium,
                          color: cs.onSurface,
                        ),
                      ),
                      if (item['description'] != null)
                        Text(
                          item['description'] as String,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item['marks'] != null)
                  Text(
                    '${item['marks']} pts',
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Spacings.smIcon, color: cs.onSurfaceVariant),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
