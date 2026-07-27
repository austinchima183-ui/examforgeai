import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';


// ═══════════════════════════════════════════════════════════════════════
// CLASS FORM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form page to create or edit a class.
class ClassFormPage extends ConsumerStatefulWidget {
  const ClassFormPage({super.key, this.classEntity, this.classId});

  /// If non-null, the form is in edit mode with a full entity.
  final ClassEntity? classEntity;

  /// If non-null, the form is in edit mode with just an ID (entity will be loaded).
  final String? classId;

  @override
  ConsumerState<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends ConsumerState<ClassFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _gradeLevelController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isActive = true;
  String? _selectedTeacherId;
  String? _selectedAcademicYear;
  bool _isSaving = false;

  static const _academicYears = [
    '2024/2025',
    '2023/2024',
    '2022/2023',
    '2021/2022',
  ];

  static const _gradeLevels = [
    'JSS 1',
    'JSS 2',
    'JSS 3',
    'SSS 1',
    'SSS 2',
    'SSS 3',
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Year 5',
    'Year 6',
    'Primary 1',
    'Primary 2',
    'Primary 3',
    'Primary 4',
    'Primary 5',
    'Primary 6',
  ];

  bool get _isEditMode => widget.classEntity != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final cls = widget.classEntity!;
      _nameController.text = cls.name;
      _sectionController.text = cls.section ?? '';
      _gradeLevelController.text = cls.gradeLevel ?? '';
      _academicYearController.text = cls.academicYear ?? '';
      _capacityController.text = cls.capacity.toString();
      _isActive = cls.isActive;
      _selectedTeacherId = cls.teacherId;
      _selectedAcademicYear = cls.academicYear;
    } else {
      _capacityController.text = '40';
      _selectedAcademicYear = _academicYears.first;
    }

    Future.microtask(() {
      ref.read(teacherListProvider.notifier).loadTeachers('current-school');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _gradeLevelController.dispose();
    _academicYearController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final teacherState = ref.watch(teacherListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Class' : 'New Class',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              'Save',
              style: tt.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Form Header ────────────────────────────────────────
              if (!_isEditMode) ...[
                Icon(
                  Icons.class_rounded,
                  size: 48,
                  color: cs.primary,
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  'Create a New Class',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  'Fill in the details below to set up a new class group.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.xl),
              ],

              // ─── Class Name ─────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name *',
                  hintText: 'e.g. JSS 1A, SSS 2 Science',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Class name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Section ────────────────────────────────────────────
              TextFormField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  labelText: 'Section',
                  hintText: 'e.g. A, B, Science, Arts',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Grade Level ────────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _gradeLevelController.text.isNotEmpty
                    ? _gradeLevelController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Grade Level',
                  prefixIcon: Icon(Icons.stairs_outlined),
                ),
                items: _gradeLevels
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ),)
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _gradeLevelController.text = value;
                  }
                },
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Academic Year ──────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedAcademicYear,
                decoration: const InputDecoration(
                  labelText: 'Academic Year *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: _academicYears
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        ),)
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Academic year is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() => _selectedAcademicYear = value);
                },
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Class Teacher ──────────────────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Class Teacher',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select a teacher (optional)'),
                  ),
                  ...teacherState.teachers.map((teacher) =>
                      DropdownMenuItem<String>(
                        value: teacher.id,
                        child: Text(
                          teacher.fullName ?? 'Unknown Teacher',
                        ),
                      ),),
                ],
                onChanged: (value) {
                  setState(() => _selectedTeacherId = value);
                },
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Capacity ───────────────────────────────────────────
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity *',
                  hintText: 'Maximum number of students',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Capacity is required';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Enter a valid number greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacings.xl),

              // ─── Active Status ──────────────────────────────────────
              SwitchListTile(
                title: Text(
                  'Active',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
                subtitle: Text(
                  _isActive
                      ? 'This class is currently active'
                      : 'This class is deactivated',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeThumbColor: cs.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacings.xxxl),

              // ─── Action Buttons ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _isEditMode ? 'Update Class' : 'Create Class',
                      onPressed: _isSaving ? null : _save,
                      variant: AppButtonVariant.elevated,
                      fullWidth: true,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Save Handler ────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final capacity = int.parse(_capacityController.text.trim());

      // Find the teacher name from the teacher list
      String? teacherName;
      if (_selectedTeacherId != null) {
        final teacherState = ref.read(teacherListProvider);
        final teacher = teacherState.teachers
            .where((t) => t.id == _selectedTeacherId)
            .firstOrNull;
        teacherName = teacher?.fullName;
      }

      if (_isEditMode) {
        final updatedClass = widget.classEntity!.copyWith(
          name: _nameController.text.trim(),
          section: _sectionController.text.trim().isEmpty
              ? null
              : _sectionController.text.trim(),
          gradeLevel: _gradeLevelController.text.trim().isEmpty
              ? null
              : _gradeLevelController.text.trim(),
          academicYear: _selectedAcademicYear,
          teacherId: _selectedTeacherId,
          teacherName: teacherName,
          capacity: capacity,
          isActive: _isActive,
        );
        await ref.read(classListProvider.notifier).updateClass(updatedClass);
      } else {
        final newClass = ClassEntity(
          id: '',
          name: _nameController.text.trim(),
          section: _sectionController.text.trim().isEmpty
              ? null
              : _sectionController.text.trim(),
          schoolId: 'current-school',
          teacherId: _selectedTeacherId,
          teacherName: teacherName,
          academicYear: _selectedAcademicYear,
          gradeLevel: _gradeLevelController.text.trim().isEmpty
              ? null
              : _gradeLevelController.text.trim(),
          capacity: capacity,
          isActive: _isActive,
        );
        await ref.read(classListProvider.notifier).createClass(newClass);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? 'Class updated successfully' : 'Class created successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
