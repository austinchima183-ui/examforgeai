import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_state.dart';

import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/generate_report_comments_usecase.dart';
import '../providers/report_comment_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// REPORT COMMENT GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI Report Comment Generator page. Teachers select a class, subject,
/// and academic session, then AI generates personalized comments for
/// each student covering academic performance, attendance, behaviour,
/// participation, strengths, and areas for improvement.
class ReportCommentGeneratorPage extends ConsumerStatefulWidget {
  const ReportCommentGeneratorPage({super.key});

  @override
  ConsumerState<ReportCommentGeneratorPage> createState() =>
      _ReportCommentGeneratorPageState();
}

class _ReportCommentGeneratorPageState
    extends ConsumerState<ReportCommentGeneratorPage> {
  // ─── Form State ───────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();

  // Sample data – in production, these would be fetched from the backend.
  final List<_DropdownOption> _classOptions = const [
    _DropdownOption(id: 'class-1', label: 'JSS 1A'),
    _DropdownOption(id: 'class-2', label: 'JSS 1B'),
    _DropdownOption(id: 'class-3', label: 'JSS 2A'),
    _DropdownOption(id: 'class-4', label: 'JSS 2B'),
    _DropdownOption(id: 'class-5', label: 'SSS 1A'),
    _DropdownOption(id: 'class-6', label: 'SSS 1B'),
  ];

  final List<_DropdownOption> _subjectOptions = const [
    _DropdownOption(id: 'subj-1', label: 'Mathematics'),
    _DropdownOption(id: 'subj-2', label: 'English Language'),
    _DropdownOption(id: 'subj-3', label: 'Physics'),
    _DropdownOption(id: 'subj-4', label: 'Chemistry'),
    _DropdownOption(id: 'subj-5', label: 'Biology'),
    _DropdownOption(id: 'subj-6', label: 'History'),
  ];

  final List<_DropdownOption> _sessionOptions = const [
    _DropdownOption(id: 'sess-1', label: '2024/2025'),
    _DropdownOption(id: 'sess-2', label: '2023/2024'),
  ];

  _DropdownOption? _selectedClass;
  _DropdownOption? _selectedSubject;
  _DropdownOption? _selectedSession;
  bool _allStudents = true;

  // Editable comment controllers keyed by comment ID.
  final Map<String, TextEditingController> _overallCommentControllers = {};
  final Map<String, TextEditingController> _academicControllers = {};
  final Map<String, TextEditingController> _attendanceControllers = {};
  final Map<String, TextEditingController> _behaviourControllers = {};
  final Map<String, TextEditingController> _participationControllers = {};

  // ─── Lifecycle ────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final c in _overallCommentControllers.values) {
      c.dispose();
    }
    for (final c in _academicControllers.values) {
      c.dispose();
    }
    for (final c in _attendanceControllers.values) {
      c.dispose();
    }
    for (final c in _behaviourControllers.values) {
      c.dispose();
    }
    for (final c in _participationControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────

  Future<void> _generateComments() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref.read(reportCommentProvider.notifier).generateComments(
          GenerateReportCommentsParams(
            classId: _selectedClass!.id,
            subjectId: _selectedSubject?.id,
            academicSessionId: _selectedSession?.id,
          ),
        );

    if (!mounted) return;
    final state = ref.read(reportCommentProvider);
    if (state.error != null) return;

    // Initialize controllers for generated comments.
    _initControllers(state.comments);
  }

  void _initControllers(List<ReportCommentEntity> comments) {
    for (final comment in comments) {
      _overallCommentControllers.putIfAbsent(
        comment.id,
        () => TextEditingController(text: comment.commentText),
      );
      _academicControllers.putIfAbsent(
        comment.id,
        () => TextEditingController(text: comment.academicPerformance ?? ''),
      );
      _attendanceControllers.putIfAbsent(
        comment.id,
        () => TextEditingController(text: comment.attendanceComment ?? ''),
      );
      _behaviourControllers.putIfAbsent(
        comment.id,
        () => TextEditingController(text: comment.behaviourComment ?? ''),
      );
      _participationControllers.putIfAbsent(
        comment.id,
        () => TextEditingController(text: comment.participationComment ?? ''),
      );
    }
  }

  Future<void> _publishComment(String commentId) async {
    await ref.read(reportCommentProvider.notifier).publishComment(commentId);

    if (!mounted) return;
    final state = ref.read(reportCommentProvider);
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(reportCommentProvider.notifier).clearSuccessMessage();
    }
  }

  Future<void> _publishAll() async {
    final state = ref.read(reportCommentProvider);
    for (final comment in state.comments) {
      if (!comment.isPublished) {
        await ref.read(reportCommentProvider.notifier).publishComment(comment.id);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All comments published successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editComment(ReportCommentEntity comment) {
    // Build updated comment from the controllers.
    final updated = comment.copyWith(
      commentText: _overallCommentControllers[comment.id]?.text ?? comment.commentText,
      academicPerformance: _academicControllers[comment.id]?.text ?? comment.academicPerformance,
      attendanceComment: _attendanceControllers[comment.id]?.text ?? comment.attendanceComment,
      behaviourComment: _behaviourControllers[comment.id]?.text ?? comment.behaviourComment,
      participationComment: _participationControllers[comment.id]?.text ?? comment.participationComment,
      isEdited: true,
    );
    ref.read(reportCommentProvider.notifier).updateComment(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(reportCommentProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Report Comments',
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

              // Class dropdown (required)
              _buildClassDropdown(context),
              Spacings.itemGap,

              // Subject dropdown
              _buildSubjectDropdown(context),
              Spacings.itemGap,

              // Academic session dropdown
              _buildSessionDropdown(context),
              Spacings.itemGap,

              // Student selection toggle
              _buildStudentSelectionToggle(context),
              Spacings.sectionGap,

              // Generate button
              AppButton(
                label: 'Generate Comments',
                onPressed: _generateComments,
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
                  onRetry: _generateComments,
                ),
              ],

              // ── Generated Comments Section ───────────────────────────
              if (state.comments.isNotEmpty) ...[
                Spacings.sectionGap,
                _buildDivider(context),
                Spacings.sectionGap,

                // Bulk Publish All
                _buildBulkPublishBar(context, state),
                Spacings.itemGap,

                // Student comment cards
                ...state.comments.map((comment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _StudentCommentCard(
                      comment: comment,
                      overallController:
                          _overallCommentControllers[comment.id],
                      academicController:
                          _academicControllers[comment.id],
                      attendanceController:
                          _attendanceControllers[comment.id],
                      behaviourController:
                          _behaviourControllers[comment.id],
                      participationController:
                          _participationControllers[comment.id],
                      onEdit: () => _editComment(comment),
                      onPublish: () => _publishComment(comment.id),
                    ),
                  );
                }),
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
            color: cs.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
          ),
          child: Icon(
            Icons.rate_review_rounded,
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
                'AI Report Comments',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                'Generate personalized comments for each student',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassDropdown(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final effectiveLabel = 'Class *';

    return DropdownButtonFormField<_DropdownOption>(
      value: _selectedClass,
      items: _classOptions
          .map((opt) => DropdownMenuItem<_DropdownOption>(
                value: opt,
                child: Text(
                  opt.label,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedClass = v),
      validator: (v) => v == null ? 'Please select a class' : null,
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
      decoration: InputDecoration(
        labelText: effectiveLabel,
        prefixIcon: Icon(Icons.class_outlined, size: Spacings.mdIcon),
      ),
      dropdownColor: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      menuMaxHeight: 300,
    );
  }

  Widget _buildSubjectDropdown(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return DropdownButtonFormField<_DropdownOption>(
      value: _selectedSubject,
      items: _subjectOptions
          .map((opt) => DropdownMenuItem<_DropdownOption>(
                value: opt,
                child: Text(
                  opt.label,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSubject = v),
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
      decoration: InputDecoration(
        labelText: 'Subject',
        prefixIcon: Icon(Icons.book_outlined, size: Spacings.mdIcon),
      ),
      dropdownColor: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      menuMaxHeight: 300,
    );
  }

  Widget _buildSessionDropdown(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return DropdownButtonFormField<_DropdownOption>(
      value: _selectedSession,
      items: _sessionOptions
          .map((opt) => DropdownMenuItem<_DropdownOption>(
                value: opt,
                child: Text(
                  opt.label,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSession = v),
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
      decoration: InputDecoration(
        labelText: 'Academic Session',
        prefixIcon: Icon(Icons.school_outlined, size: Spacings.mdIcon),
      ),
      dropdownColor: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      menuMaxHeight: 300,
    );
  }

  Widget _buildStudentSelectionToggle(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline_rounded,
              size: Spacings.mdIcon, color: cs.onSurfaceVariant),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Text(
              'All Students',
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),
          Switch(
            value: _allStudents,
            onChanged: (v) => setState(() => _allStudents = v),
            activeColor: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
    );
  }

  Widget _buildBulkPublishBar(BuildContext context, ReportCommentState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final publishedCount =
        state.comments.where((c) => c.isPublished).length;
    final totalCount = state.comments.length;

    return AppCard(
      child: Row(
        children: [
          Icon(Icons.rate_review_rounded, size: Spacings.mdIcon, color: cs.primary),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount Comments Generated',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '$publishedCount of $totalCount published',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Publish All',
            onPressed: _publishAll,
            variant: AppButtonVariant.elevated,
            icon: Icons.publish_rounded,
            size: AppButtonSize.small,
            isLoading: state.isPublishing,
            isDisabled: state.isPublishing || publishedCount == totalCount,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STUDENT COMMENT CARD
// ═══════════════════════════════════════════════════════════════════════

/// A card displaying a single student's AI-generated report comment with
/// editable fields for each section.
class _StudentCommentCard extends StatelessWidget {
  const _StudentCommentCard({
    required this.comment,
    this.overallController,
    this.academicController,
    this.attendanceController,
    this.behaviourController,
    this.participationController,
    this.onEdit,
    this.onPublish,
  });

  final ReportCommentEntity comment;
  final TextEditingController? overallController;
  final TextEditingController? academicController;
  final TextEditingController? attendanceController;
  final TextEditingController? behaviourController;
  final TextEditingController? participationController;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Student name from metadata or fallback
    final studentName = comment.metadata['studentName'] as String? ??
        'Student ${comment.studentId?.substring(0, 8) ?? 'Unknown'}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Student name + AI badge ──────────────────────────
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    cs.primary.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
                child: Text(
                  studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                  style: tt.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    if (comment.isEdited)
                      Text(
                        'Edited',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              // AI-generated indicator
              if (comment.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(
                        alpha: context.isDarkMode ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: Spacings.smIcon, color: cs.tertiary),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'AI',
                        style: tt.labelSmall?.copyWith(
                          color: cs.tertiary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Published badge
              if (comment.isPublished) ...[
                const SizedBox(width: Spacings.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(
                        alpha: context.isDarkMode ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    'Published',
                    style: tt.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Spacings.itemGap,

          // ── Academic Performance ─────────────────────────────────────
          _buildSectionLabel(context, 'Academic Performance'),
          AppTextField(
            controller: academicController,
            maxLines: 2,
            minLines: 1,
            hint: 'Academic performance comment…',
          ),
          const SizedBox(height: Spacings.sm),

          // ── Attendance ───────────────────────────────────────────────
          _buildSectionLabel(context, 'Attendance'),
          AppTextField(
            controller: attendanceController,
            maxLines: 2,
            minLines: 1,
            hint: 'Attendance comment…',
          ),
          const SizedBox(height: Spacings.sm),

          // ── Behaviour ────────────────────────────────────────────────
          _buildSectionLabel(context, 'Behaviour'),
          AppTextField(
            controller: behaviourController,
            maxLines: 2,
            minLines: 1,
            hint: 'Behaviour comment…',
          ),
          const SizedBox(height: Spacings.sm),

          // ── Participation ────────────────────────────────────────────
          _buildSectionLabel(context, 'Participation'),
          AppTextField(
            controller: participationController,
            maxLines: 2,
            minLines: 1,
            hint: 'Participation comment…',
          ),
          const SizedBox(height: Spacings.sm),

          // ── Strengths ────────────────────────────────────────────────
          if (comment.strengths.isNotEmpty) ...[
            _buildSectionLabel(context, 'Strengths'),
            Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: comment.strengths.map((s) {
                return Chip(
                  label: Text(s, style: tt.bodySmall),
                  backgroundColor: Colors.green
                      .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: Spacings.sm),
          ],

          // ── Areas for Improvement ────────────────────────────────────
          if (comment.areasForImprovement.isNotEmpty) ...[
            _buildSectionLabel(context, 'Areas for Improvement'),
            Wrap(
              spacing: Spacings.xs,
              runSpacing: Spacings.xs,
              children: comment.areasForImprovement.map((s) {
                return Chip(
                  label: Text(s, style: tt.bodySmall),
                  backgroundColor: Colors.orange
                      .withValues(alpha: context.isDarkMode ? 0.20 : 0.10),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: Spacings.sm),
          ],

          // ── Overall Comment (commentText) ────────────────────────────
          _buildSectionLabel(context, 'Overall Comment'),
          AppTextField(
            controller: overallController,
            maxLines: 3,
            minLines: 2,
            hint: 'Overall comment…',
          ),
          Spacings.itemGap,

          // ── Action Buttons ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Edit',
                onPressed: onEdit,
                variant: AppButtonVariant.outlined,
                icon: Icons.edit_outlined,
                size: AppButtonSize.small,
              ),
              const SizedBox(width: Spacings.sm),
              AppButton(
                label: comment.isPublished ? 'Published' : 'Publish',
                onPressed: comment.isPublished ? null : onPublish,
                variant: AppButtonVariant.elevated,
                icon: comment.isPublished
                    ? Icons.check_circle_rounded
                    : Icons.publish_rounded,
                size: AppButtonSize.small,
                isDisabled: comment.isPublished,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.xs),
      child: Text(
        label,
        style: tt.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASS
// ═══════════════════════════════════════════════════════════════════════

class _DropdownOption {
  const _DropdownOption({required this.id, required this.label});
  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DropdownOption && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
