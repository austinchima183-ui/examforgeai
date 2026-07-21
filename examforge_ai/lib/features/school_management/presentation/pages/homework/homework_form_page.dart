import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../routing/route_names.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/homework_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/subject_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK FORM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form page for creating or editing a homework assignment.
///
/// Fields: title, description, instructions (multiline), class dropdown,
/// subject dropdown, total marks, deadline (date+time picker), allow late
/// submission toggle, file attachments. Publish or save as draft.
class HomeworkFormPage extends ConsumerStatefulWidget {
  const HomeworkFormPage({super.key, this.homeworkId});

  /// If provided, we edit an existing homework. Otherwise, create new.
  final String? homeworkId;

  @override
  ConsumerState<HomeworkFormPage> createState() => _HomeworkFormPageState();
}

class _HomeworkFormPageState extends ConsumerState<HomeworkFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // ─── Form controllers ──────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _totalMarksController = TextEditingController(text: '100');

  String? _selectedClassId;
  String? _selectedSubjectId;
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;
  bool _allowLateSubmission = false;
  bool _isSaving = false;
  bool _isPublishing = false;

  final List<String> _attachmentUrls = [];

  bool get _isEditing => widget.homeworkId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
      ref.read(subjectListProvider.notifier).loadSubjects(schoolId: 'current-school');

      if (_isEditing) {
        ref.read(homeworkDetailProvider.notifier).loadHomework(widget.homeworkId!);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  // ─── Date / Time Pickers ───────────────────────────────────────────

  Future<void> _pickDeadlineDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _deadlineDate = picked);
    }
  }

  Future<void> _pickDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _deadlineTime = picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ─── Save ──────────────────────────────────────────────────────────

  Future<void> _saveHomework({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadlineDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline date.')),
      );
      return;
    }

    setState(() {
      if (publish) {
        _isPublishing = true;
      } else {
        _isSaving = true;
      }
    });

    final deadline = DateTime(
      _deadlineDate!.year,
      _deadlineDate!.month,
      _deadlineDate!.day,
      _deadlineTime?.hour ?? 23,
      _deadlineTime?.minute ?? 59,
    );

    final homework = HomeworkEntity(
      id: _isEditing ? widget.homeworkId! : '',
      schoolId: 'current-school',
      termId: 'current-term',
      classId: _selectedClassId ?? '',
      subjectId: _selectedSubjectId ?? '',
      teacherId: 'current-teacher',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      attachmentUrls: _attachmentUrls,
      totalMarks: double.tryParse(_totalMarksController.text.trim()) ?? 100,
      deadline: deadline,
      allowLateSubmission: _allowLateSubmission,
      status: publish ? HomeworkStatus.published : HomeworkStatus.draft,
      isPublished: publish,
    );

    if (_isEditing) {
      await ref.read(homeworkListProvider.notifier).updateHomework(homework);
    } else {
      await ref.read(homeworkListProvider.notifier).createHomework(homework);
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isPublishing = false;
      });
      context.pop();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classState = ref.watch(classListProvider);
    final subjectState = ref.watch(subjectListProvider);
    final detailState = ref.watch(homeworkDetailProvider);

    // Pre-fill form when editing
    if (_isEditing && detailState.homework != null && _titleController.text.isEmpty) {
      final hw = detailState.homework!;
      _titleController.text = hw.title;
      _descriptionController.text = hw.description ?? '';
      _instructionsController.text = hw.instructions ?? '';
      _totalMarksController.text = hw.totalMarks.toString();
      _selectedClassId = hw.classId;
      _selectedSubjectId = hw.subjectId;
      _deadlineDate = hw.deadline;
      if (hw.deadline != null) {
        _deadlineTime = TimeOfDay.fromDateTime(hw.deadline!);
      }
      _allowLateSubmission = hw.allowLateSubmission;
      _attachmentUrls.addAll(hw.attachmentUrls);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Homework' : 'New Homework',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacings.md),
            child: AppButton(
              label: 'Save Draft',
              onPressed: _isSaving || _isPublishing ? null : () => _saveHomework(publish: false),
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Homework Details ────────────────────────────────────
              _FormSectionHeader(
                title: 'Homework Details',
                icon: Icons.assignment_outlined,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Title',
                controller: _titleController,
                isRequired: true,
                prefixIcon: Icons.title_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Description',
                controller: _descriptionController,
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                hint: 'Brief description of the homework...',
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Instructions',
                controller: _instructionsController,
                prefixIcon: Icons.list_alt_outlined,
                maxLines: 5,
                hint: 'Detailed instructions for students...',
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Class & Subject ────────────────────────────────────
              _FormSectionHeader(
                title: 'Class & Subject',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class *',
                        prefixIcon: Icon(Icons.class_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: classState.classes
                          .map((c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedClassId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        prefixIcon: Icon(Icons.book_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: subjectState.subjects
                          .map((s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Marks & Deadline ───────────────────────────────────
              _FormSectionHeader(
                title: 'Marks & Deadline',
                icon: Icons.timer_outlined,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Total Marks',
                controller: _totalMarksController,
                prefixIcon: Icons.grade_outlined,
                isRequired: true,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDeadlineDate,
                      child: AbsorbPointer(
                        child: AppTextField(
                          label: 'Deadline Date',
                          controller: TextEditingController(
                            text: _formatDate(_deadlineDate),
                          ),
                          prefixIcon: Icons.calendar_today_outlined,
                          isRequired: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDeadlineTime,
                      child: AbsorbPointer(
                        child: AppTextField(
                          label: 'Deadline Time',
                          controller: TextEditingController(
                            text: _formatTime(_deadlineTime),
                          ),
                          prefixIcon: Icons.access_time_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              SwitchListTile(
                title: const Text('Allow Late Submission'),
                subtitle: const Text('Students can submit after the deadline'),
                value: _allowLateSubmission,
                onChanged: (v) => setState(() => _allowLateSubmission = v),
                activeColor: cs.primary,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Attachments ────────────────────────────────────────
              _FormSectionHeader(
                title: 'Attachments',
                icon: Icons.attach_file_rounded,
              ),
              const SizedBox(height: Spacings.md),
              if (_attachmentUrls.isNotEmpty)
                ..._attachmentUrls.map((url) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.sm),
                      child: Chip(
                        label: Text(url.split('/').last),
                        deleteIcon: const Icon(Icons.close_rounded, size: Spacings.smIcon),
                        onDeleted: () {
                          setState(() => _attachmentUrls.remove(url));
                        },
                      ),
                    )),
              OutlinedButton.icon(
                onPressed: () {
                  // Future: file picker
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Attachment'),
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Action Buttons ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Save as Draft',
                      onPressed: _isSaving || _isPublishing
                          ? null
                          : () => _saveHomework(publish: false),
                      variant: AppButtonVariant.outlined,
                      fullWidth: true,
                      isLoading: _isSaving,
                      icon: Icons.save_outlined,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppButton(
                      label: 'Publish',
                      onPressed: _isSaving || _isPublishing
                          ? null
                          : () => _saveHomework(publish: true),
                      variant: AppButtonVariant.elevated,
                      fullWidth: true,
                      isLoading: _isPublishing,
                      icon: Icons.publish_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FORM SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════

class _FormSectionHeader extends StatelessWidget {
  const _FormSectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacings.sm),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Icon(icon, size: Spacings.mdIcon, color: cs.primary),
        ),
        const SizedBox(width: Spacings.md),
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
