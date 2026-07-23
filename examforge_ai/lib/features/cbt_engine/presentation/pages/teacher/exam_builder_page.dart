import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/dependency_injection.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../question_bank/domain/entities/question_entities.dart';
import '../../widgets/question_selector_widget.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM BUILDER PAGE (Teacher)
// ═══════════════════════════════════════════════════════════════════════

/// Exam creation/editing page with a multi-section scrollable form.
class ExamBuilderPage extends ConsumerStatefulWidget {
  const ExamBuilderPage({super.key, this.examId});

  /// Optional exam ID for editing an existing exam.
  final String? examId;

  @override
  ConsumerState<ExamBuilderPage> createState() => _ExamBuilderPageState();
}

class _ExamBuilderPageState extends ConsumerState<ExamBuilderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _passMarkController = TextEditingController(text: '50');
  final _timeLimitController = TextEditingController(text: '60');
  final _gracePeriodController = TextEditingController(text: '0');
  final _allowedAttemptsController = TextEditingController(text: '1');
  final _negativeMarkController = TextEditingController(text: '0');

  // Form state
  String _selectedSubjectId = '';
  String _selectedClassId = '';
  String _selectedSessionId = '';
  ExamType _examType = ExamType.schoolExam;
  DateTime? _startTime;
  DateTime? _endTime;
  String _passMarkType = 'percentage';
  bool _negativeMarkingEnabled = false;
  bool _autoSubmit = true;
  bool _randomizeQuestions = false;
  bool _randomizeOptions = false;
  String _showResults = 'after_submission';
  bool _showCorrectAnswers = false;
  bool _showExplanations = false;
  bool _requireFullScreen = false;
  bool _allowResume = true;
  bool _browserLockdown = false;
  Set<String> _selectedQuestionIds = {};

  static const _sectionTabs = [
    'Basic Info',
    'Schedule',
    'Scoring',
    'Questions',
    'Students',
    'Settings',
    'Security',
    'Instructions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sectionTabs.length, vsync: this);

    if (widget.examId != null) {
      // Load existing exam for editing
      Future.microtask(() {
        ref.read(examBuilderProvider.notifier).loadExamForEdit(widget.examId!);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _passMarkController.dispose();
    _timeLimitController.dispose();
    _gracePeriodController.dispose();
    _allowedAttemptsController.dispose();
    _negativeMarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(examBuilderProvider);
    final isEditing = widget.examId != null;

    return PopScope(
      canPop: !state.isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && state.isSaving) return;
        if (!didPop) {
          final shouldLeave = await AppDialog.showConfirm(
            context: context,
            title: 'Leave Editor?',
            message: 'You have unsaved changes. Are you sure you want to leave?',
            isDestructive: true,
            confirmText: 'Leave',
          );
          if (shouldLeave == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: isEditing ? 'Edit Exam' : 'Create Exam',
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: AppButton(
                label: 'Save Draft',
                onPressed: state.isSaving ? null : _saveDraft,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                isLoading: state.isSaving,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: Spacings.md),
              child: AppButton(
                label: 'Publish',
                onPressed: state.isSaving ? null : _publishExam,
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.small,
                isLoading: state.isPublishing,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Section tabs
            Container(
              color: cs.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                labelStyle: tt.labelLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
                tabs: _sectionTabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            // Form content
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBasicInfoSection(context),
                        _buildScheduleSection(context),
                        _buildScoringSection(context),
                        _buildQuestionsSection(context),
                        _buildStudentsSection(context),
                        _buildSettingsSection(context),
                        _buildSecuritySection(context),
                        _buildInstructionsSection(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 1: Basic Info ──────────────────────────────────────────

  Widget _buildBasicInfoSection(BuildContext context) {
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Basic Information'),
          const SizedBox(height: Spacings.lg),
          AppTextField(
            label: 'Exam Title',
            hint: 'e.g. Biology Mid-Term Exam',
            controller: _titleController,
            isRequired: true,
            prefixIcon: Icons.title_rounded,
          ),
          const SizedBox(height: Spacings.md),
          AppTextField(
            label: 'Description',
            hint: 'Brief description of the exam',
            controller: _descriptionController,
            maxLines: 3,
            minLines: 2,
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Subject',
                  items: const ['Mathematics', 'English', 'Biology', 'Physics', 'Chemistry'],
                  selectedItem: _selectedSubjectId.isNotEmpty ? _selectedSubjectId : null,
                  onChanged: (v) => setState(() => _selectedSubjectId = v ?? ''),
                  itemLabel: (v) => v,
                  isRequired: true,
                  prefixIcon: Icons.subject_rounded,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Class',
                  items: const ['SS1', 'SS2', 'SS3', 'JSS1', 'JSS2', 'JSS3'],
                  selectedItem: _selectedClassId.isNotEmpty ? _selectedClassId : null,
                  onChanged: (v) => setState(() => _selectedClassId = v ?? ''),
                  itemLabel: (v) => v,
                  isRequired: true,
                  prefixIcon: Icons.class_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Academic Session',
                  items: const ['2024/2025', '2023/2024'],
                  selectedItem: _selectedSessionId.isNotEmpty ? _selectedSessionId : null,
                  onChanged: (v) => setState(() => _selectedSessionId = v ?? ''),
                  itemLabel: (v) => v,
                  isRequired: true,
                  prefixIcon: Icons.school_rounded,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: AppDropdownField<ExamType>(
                  label: 'Exam Type',
                  items: ExamType.values,
                  selectedItem: _examType,
                  onChanged: (v) => setState(() => _examType = v ?? _examType),
                  itemLabel: (v) => v.label,
                  isRequired: true,
                  prefixIcon: Icons.category_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section 2: Schedule ────────────────────────────────────────────

  Widget _buildScheduleSection(BuildContext context) {
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Schedule'),
          const SizedBox(height: Spacings.lg),
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  context: context,
                  label: 'Start Date & Time',
                  value: _startTime,
                  onPressed: () async {
                    final picked = await _pickDateTime(context, _startTime);
                    if (picked != null) setState(() => _startTime = picked);
                  },
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: _buildDateTimePicker(
                  context: context,
                  label: 'End Date & Time',
                  value: _endTime,
                  onPressed: () async {
                    final picked = await _pickDateTime(context, _endTime);
                    if (picked != null) setState(() => _endTime = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Time Limit (minutes)',
                  controller: _timeLimitController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timer_rounded,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: AppTextField(
                  label: 'Grace Period (minutes)',
                  controller: _gracePeriodController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section 3: Scoring ─────────────────────────────────────────────

  Widget _buildScoringSection(BuildContext context) {
    final cs = context.colorScheme;
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Scoring'),
          const SizedBox(height: Spacings.lg),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Total Marks',
                  hint: 'Auto-calculated from questions',
                  controller: TextEditingController(
                    text: '${_calculateTotalMarks()}',
                  ),
                  readOnly: true,
                  prefixIcon: Icons.assessment_rounded,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: AppTextField(
                  label: 'Pass Mark',
                  controller: _passMarkController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.check_circle_rounded,
                  isRequired: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          AppDropdownField<String>(
            label: 'Pass Mark Type',
            items: const ['percentage', 'absolute'],
            selectedItem: _passMarkType,
            onChanged: (v) => setState(() => _passMarkType = v ?? 'percentage'),
            itemLabel: (v) => v == 'percentage' ? 'Percentage (%)' : 'Absolute Marks',
            prefixIcon: Icons.percent_rounded,
          ),
          const SizedBox(height: Spacings.md),
          SwitchListTile(
            title: Text('Negative Marking',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Deduct marks for wrong answers',
                style: context.textTheme.bodySmall,),
            value: _negativeMarkingEnabled,
            onChanged: (v) => setState(() => _negativeMarkingEnabled = v),
            activeThumbColor: cs.primary,
          ),
          if (_negativeMarkingEnabled)
            Padding(
              padding: const EdgeInsets.only(top: Spacings.sm),
              child: AppTextField(
                label: 'Negative Mark Value',
                controller: _negativeMarkController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.remove_circle_rounded,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Section 4: Questions ───────────────────────────────────────────

  Widget _buildQuestionsSection(BuildContext context) {
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Questions'),
          const SizedBox(height: Spacings.lg),
          QuestionSelectorWidget(
            availableQuestions: const [], // Would be loaded from QB provider
            selectedQuestionIds: _selectedQuestionIds,
            onSelectionChanged: (ids) {
              setState(() => _selectedQuestionIds = ids);
            },
            onImportSelected: () {
              // Handle import
            },
          ),
          const SizedBox(height: Spacings.xl),
          if (_selectedQuestionIds.isNotEmpty) ...[
            Text(
              'Selected Questions (${_selectedQuestionIds.length})',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.md),
            // Display selected questions list with reorder/remove
            Text(
              'Reorder and remove questions below:',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Section 5: Students ────────────────────────────────────────────

  Widget _buildStudentsSection(BuildContext context) {
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Assign Students'),
          const SizedBox(height: Spacings.lg),
          const AppTextField(
            label: 'Search Students',
            hint: 'Type a student name or ID…',
            prefixIcon: Icons.search_rounded,
          ),
          const SizedBox(height: Spacings.md),
          AppButton(
            label: 'Add All Students in Class',
            onPressed: () {},
            variant: AppButtonVariant.tonal,
            icon: Icons.group_add_rounded,
          ),
          const SizedBox(height: Spacings.xl),
          const Center(
            child: AppEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Students Added',
              subtitle: 'Search and add students, or add all students in the class.',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 6: Settings ────────────────────────────────────────────

  Widget _buildSettingsSection(BuildContext context) {
    final cs = context.colorScheme;
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Exam Settings'),
          const SizedBox(height: Spacings.lg),
          AppTextField(
            label: 'Allowed Attempts',
            controller: _allowedAttemptsController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.replay_rounded,
          ),
          const SizedBox(height: Spacings.md),
          SwitchListTile(
            title: Text('Auto Submit on Time Up',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Automatically submit the exam when time runs out',
                style: context.textTheme.bodySmall,),
            value: _autoSubmit,
            onChanged: (v) => setState(() => _autoSubmit = v),
            activeThumbColor: cs.primary,
          ),
          SwitchListTile(
            title: Text('Randomize Questions',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Shuffle question order for each student',
                style: context.textTheme.bodySmall,),
            value: _randomizeQuestions,
            onChanged: (v) => setState(() => _randomizeQuestions = v),
            activeThumbColor: cs.primary,
          ),
          SwitchListTile(
            title: Text('Randomize Options',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Shuffle answer options within each question',
                style: context.textTheme.bodySmall,),
            value: _randomizeOptions,
            onChanged: (v) => setState(() => _randomizeOptions = v),
            activeThumbColor: cs.primary,
          ),
          const SizedBox(height: Spacings.md),
          AppDropdownField<String>(
            label: 'Show Results',
            items: const ['immediate', 'after_submission', 'after_grading', 'manual'],
            selectedItem: _showResults,
            onChanged: (v) => setState(() => _showResults = v ?? 'after_submission'),
            itemLabel: (v) => switch (v) {
              'immediate' => 'Immediately',
              'after_submission' => 'After Submission',
              'after_grading' => 'After Grading',
              'manual' => 'Manual Release',
              _ => v,
            },
            prefixIcon: Icons.visibility_rounded,
          ),
          const SizedBox(height: Spacings.md),
          SwitchListTile(
            title: Text('Show Correct Answers',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Show correct answers in results',
                style: context.textTheme.bodySmall,),
            value: _showCorrectAnswers,
            onChanged: (v) => setState(() => _showCorrectAnswers = v),
            activeThumbColor: cs.primary,
          ),
          SwitchListTile(
            title: Text('Show Explanations',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Show explanations in results',
                style: context.textTheme.bodySmall,),
            value: _showExplanations,
            onChanged: (v) => setState(() => _showExplanations = v),
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }

  // ─── Section 7: Security ────────────────────────────────────────────

  Widget _buildSecuritySection(BuildContext context) {
    final cs = context.colorScheme;
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Security'),
          const SizedBox(height: Spacings.lg),
          SwitchListTile(
            title: Text('Require Full Screen',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Students must remain in full-screen mode',
                style: context.textTheme.bodySmall,),
            value: _requireFullScreen,
            onChanged: (v) => setState(() => _requireFullScreen = v),
            activeThumbColor: cs.primary,
          ),
          SwitchListTile(
            title: Text('Browser Lockdown',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Prevent copy, paste, right-click during exam',
                style: context.textTheme.bodySmall,),
            value: _browserLockdown,
            onChanged: (v) => setState(() => _browserLockdown = v),
            activeThumbColor: cs.primary,
          ),
          SwitchListTile(
            title: Text('Allow Resume',
                style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,),),
            subtitle: Text('Allow students to resume after disconnection',
                style: context.textTheme.bodySmall,),
            value: _allowResume,
            onChanged: (v) => setState(() => _allowResume = v),
            activeThumbColor: cs.primary,
          ),
          const SizedBox(height: Spacings.md),
          const AppTextField(
            label: 'IP Restriction (comma-separated)',
            hint: 'e.g. 192.168.1.0/24, 10.0.0.0/8',
            prefixIcon: Icons.lock_rounded,
          ),
        ],
      ),
    );
  }

  // ─── Section 8: Instructions ────────────────────────────────────────

  Widget _buildInstructionsSection(BuildContext context) {
    return _sectionScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Exam Instructions'),
          const SizedBox(height: Spacings.lg),
          AppTextField(
            label: 'Instructions for Students',
            hint: 'Enter detailed instructions that students will see before starting the exam…',
            controller: _instructionsController,
            maxLines: 15,
            minLines: 10,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  Widget _sectionScroll({required Widget child}) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onPressed,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final displayText = value != null
        ? '${months[value.month]} ${value.day}, ${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
        : 'Select date & time';

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_rounded),
        ),
        child: Text(
          displayText,
          style: tt.bodyLarge?.copyWith(
            color: value != null ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return null;

    return DateTime(
      date.year, date.month, date.day,
      time.hour, time.minute,
    );
  }

  double _calculateTotalMarks() {
    // In production, calculate from selected questions
    return 0.0;
  }

  Future<void> _saveDraft() async {
    if (_titleController.text.trim().isEmpty) {
      AppDialog.showError(
        context: context,
        title: 'Missing Title',
        message: 'Please enter an exam title before saving.',
      );
      return;
    }

    await ref.read(examBuilderProvider.notifier).saveExam();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully')),
      );
    }
  }

  Future<void> _publishExam() async {
    if (_titleController.text.trim().isEmpty) {
      AppDialog.showError(
        context: context,
        title: 'Missing Information',
        message: 'Please fill in all required fields before publishing.',
      );
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Publish Exam?',
      message: 'Once published, the exam cannot be edited. Students will be able to see it.',
      confirmText: 'Publish',
    );

    if (confirmed == true) {
      await ref.read(examBuilderProvider.notifier).publishExam();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam published successfully')),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
