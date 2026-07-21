import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../routing/route_names.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/student_provider.dart';
import '../../providers/class_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// PROMOTION PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Bulk promotion interface for promoting students from one class to another.
/// Allows selecting source class, target class, and setting promotion status
/// per student with checkboxes and dropdowns.
class PromotionPage extends ConsumerStatefulWidget {
  const PromotionPage({super.key});

  @override
  ConsumerState<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends ConsumerState<PromotionPage> {
  String? _sourceClassId;
  String? _targetClassId;
  final Map<String, PromotionStatus> _studentStatuses = {};
  final Map<String, bool> _selectedStudents = {};
  final Map<String, double> _averageScores = {};
  bool _isPromoting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
    });
  }

  void _onSourceClassChanged(String? classId) {
    setState(() {
      _sourceClassId = classId;
      _studentStatuses.clear();
      _selectedStudents.clear();
      _averageScores.clear();
    });
    if (classId != null) {
      ref.read(studentListProvider.notifier).filterByClass(classId);
    }
  }

  void _selectAll(List<StudentProfileEntity> students) {
    setState(() {
      for (final s in students) {
        _selectedStudents[s.id] = true;
        _studentStatuses.putIfAbsent(s.id, () => PromotionStatus.promoted);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedStudents.clear();
    });
  }

  Future<void> _promoteSelected() async {
    final selectedIds = _selectedStudents.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedIds.isEmpty || _targetClassId == null) {
      AppDialog.showInfo(
        context: context,
        title: 'Cannot Promote',
        message: 'Please select students and a target class.',
      );
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Confirm Promotion',
      message:
          'You are about to promote ${selectedIds.length} student(s). This action cannot be undone.',
      confirmText: 'Promote',
      isDestructive: false,
    );

    if (confirmed != true) return;

    setState(() => _isPromoting = true);

    final studentState = ref.read(studentListProvider);
    for (final id in selectedIds) {
      final student = studentState.students.where((s) => s.id == id).firstOrNull;
      if (student != null) {
        await ref.read(studentListProvider.notifier).promoteStudent(
          studentId: student.userId,
          schoolId: student.schoolId,
          toClassId: _targetClassId!,
          promotionStatus: _studentStatuses[id] ?? PromotionStatus.promoted,
          fromClassId: _sourceClassId,
          averageScore: _averageScores[id],
        );
      }
    }

    if (mounted) {
      setState(() => _isPromoting = false);
      AppDialog.showSuccess(
        context: context,
        title: 'Promotion Complete',
        message: '${selectedIds.length} student(s) have been promoted.',
        autoDismissDuration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _promoteAll(List<StudentProfileEntity> students) async {
    _selectAll(students);
    await _promoteSelected();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classState = ref.watch(classListProvider);
    final studentState = ref.watch(studentListProvider);

    final sourceStudents = studentState.students
        .where((s) => s.isActive && !s.isGraduated)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bulk Promotion',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Class Selection Row ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppDropdownField<ClassEntity>(
                    label: 'Source Class',
                    items: classState.classes,
                    selectedItem: _sourceClassId != null
                        ? classState.classes
                            .where((c) => c.id == _sourceClassId)
                            .firstOrNull
                        : null,
                    onChanged: (c) => _onSourceClassChanged(c?.id),
                    isRequired: true,
                    itemLabel: (c) => c.name,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Icon(Icons.arrow_forward_rounded, color: cs.primary),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppDropdownField<ClassEntity>(
                    label: 'Target Class',
                    items: classState.classes
                        .where((c) => c.id != _sourceClassId)
                        .toList(),
                    selectedItem: _targetClassId != null
                        ? classState.classes
                            .where((c) => c.id == _targetClassId)
                            .firstOrNull
                        : null,
                    onChanged: (c) => setState(() => _targetClassId = c?.id),
                    isRequired: true,
                    itemLabel: (c) => c.name,
                  ),
                ),
              ],
            ),
          ),

          // ─── Action Buttons ───────────────────────────────────────
          if (_sourceClassId != null && sourceStudents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: Row(
                children: [
                  Text(
                    '${sourceStudents.length} students',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _selectAll(sourceStudents),
                    icon: const Icon(Icons.select_all_rounded, size: Spacings.smIcon),
                    label: const Text('Select All'),
                  ),
                  TextButton.icon(
                    onPressed: _deselectAll,
                    icon: const Icon(Icons.deselect_rounded, size: Spacings.smIcon),
                    label: const Text('Deselect All'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: Spacings.sm),

          // ─── Student Table ────────────────────────────────────────
          Expanded(
            child: _buildStudentTable(context, sourceStudents, studentState),
          ),

          // ─── Bottom Action Bar ────────────────────────────────────
          if (_sourceClassId != null && sourceStudents.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(Spacings.lg),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedStudents.entries.where((e) => e.value).length} selected',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Promote Selected',
                    onPressed: _isPromoting ? null : _promoteSelected,
                    variant: AppButtonVariant.outlined,
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isPromoting,
                  ),
                  const SizedBox(width: Spacings.md),
                  AppButton(
                    label: 'Promote All',
                    onPressed: _isPromoting
                        ? null
                        : () => _promoteAll(sourceStudents),
                    variant: AppButtonVariant.elevated,
                    icon: Icons.trending_up_rounded,
                    isLoading: _isPromoting,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentTable(
    BuildContext context,
    List<StudentProfileEntity> students,
    StudentListState state,
  ) {
    if (_sourceClassId == null) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'Select a Source Class',
        subtitle: 'Choose a class to see its students for promotion.',
      );
    }

    if (state.isLoading && students.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && students.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(studentListProvider.notifier).filterByClass(_sourceClassId),
      );
    }

    if (students.isEmpty) {
      return const AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Students in Class',
        subtitle: 'This class has no active students to promote.',
      );
    }

    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final isSelected = _selectedStudents[student.id] ?? false;
        final status = _studentStatuses[student.id] ?? PromotionStatus.promoted;

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      _selectedStudents[student.id] = v ?? false;
                      if (v == true) {
                        _studentStatuses.putIfAbsent(
                          student.id,
                          () => PromotionStatus.promoted,
                        );
                      }
                    });
                  },
                  activeColor: cs.primary,
                ),
                const SizedBox(width: Spacings.sm),

                // Student info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName ?? 'Unknown',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        student.admissionNumber,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current class
                Expanded(
                  flex: 2,
                  child: Text(
                    student.currentClassName ?? '—',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),

                // Average score input
                SizedBox(
                  width: 70,
                  child: AppTextField(
                    hint: 'Score',
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final score = double.tryParse(v);
                      if (score != null) {
                        _averageScores[student.id] = score;
                      }
                    },
                  ),
                ),
                const SizedBox(width: Spacings.sm),

                // Promotion status dropdown
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<PromotionStatus>(
                    value: status,
                    isDense: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                    ),
                    items: PromotionStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.label,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: isSelected
                        ? (v) {
                            if (v != null) {
                              setState(() => _studentStatuses[student.id] = v);
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
