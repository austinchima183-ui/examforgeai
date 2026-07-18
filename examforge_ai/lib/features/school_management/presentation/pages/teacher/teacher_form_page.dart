import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/school_management_entities.dart';
import '../providers/teacher_provider.dart';
import '../providers/school_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// TEACHER FORM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form page for creating or editing a teacher profile.
/// Sections: Personal Info, Employment Info, Department assignment.
class TeacherFormPage extends ConsumerStatefulWidget {
  const TeacherFormPage({super.key, this.teacherId});

  /// If provided, we are editing an existing teacher. Otherwise, creating new.
  final String? teacherId;

  @override
  ConsumerState<TeacherFormPage> createState() => _TeacherFormPageState();
}

class _TeacherFormPageState extends ConsumerState<TeacherFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // ─── Personal Info Controllers ──────────────────────────────────
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  // ─── Employment Info Controllers ────────────────────────────────
  final _employeeIdController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  String? _selectedDepartmentId;
  EmploymentType _employmentType = EmploymentType.fullTime;
  DateTime? _employmentStartDate;

  bool _isSaving = false;

  bool get _isEditing => widget.teacherId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(schoolDetailProvider.notifier).loadSchool('current-school');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final schoolState = ref.read(schoolDetailProvider);
    final department = schoolState.departments
        .where((d) => d.id == _selectedDepartmentId)
        .firstOrNull;

    final profile = TeacherProfileEntity(
      id: _isEditing ? widget.teacherId! : '',
      userId: '',
      schoolId: 'current-school',
      employeeId: _employeeIdController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      qualification: _qualificationController.text.trim().isNotEmpty
          ? _qualificationController.text.trim()
          : null,
      specialization: _specializationController.text.trim().isNotEmpty
          ? _specializationController.text.trim()
          : null,
      departmentId: _selectedDepartmentId,
      departmentName: department?.name,
      employmentType: _employmentType,
      employmentStartDate: _employmentStartDate,
      fullName:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    if (_isEditing) {
      await ref.read(teacherListProvider.notifier).updateTeacher(profile);
    } else {
      await ref.read(teacherListProvider.notifier).createTeacher(profile);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
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
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, "0")}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final schoolState = ref.watch(schoolDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Teacher' : 'New Teacher',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacings.md),
            child: AppButton(
              label: 'Save',
              onPressed: _isSaving ? null : _saveTeacher,
              variant: AppButtonVariant.elevated,
              size: AppButtonSize.small,
              isLoading: _isSaving,
              icon: Icons.check_rounded,
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
              // ─── Personal Information Section ──────────────────────
              _FormSectionHeader(
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'First Name',
                      controller: _firstNameController,
                      isRequired: true,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      isRequired: true,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Phone',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(
                        current: _dateOfBirth,
                        onPicked: (d) => setState(() => _dateOfBirth = d),
                      ),
                      child: AbsorbPointer(
                        child: AppTextField(
                          label: 'Date of Birth',
                          controller: TextEditingController(
                            text: _formatDate(_dateOfBirth),
                          ),
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'Gender',
                      items: const ['Male', 'Female'],
                      selectedItem: _gender,
                      onChanged: (v) => setState(() => _gender = v),
                      itemLabel: (v) => v,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Employment Information Section ────────────────────
              _FormSectionHeader(
                title: 'Employment Information',
                icon: Icons.work_outline_rounded,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Employee ID',
                controller: _employeeIdController,
                isRequired: true,
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Qualification',
                controller: _qualificationController,
                prefixIcon: Icons.school_outlined,
                hint: 'E.g., B.Ed, M.Sc, Ph.D',
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Specialization',
                controller: _specializationController,
                prefixIcon: Icons.stars_outlined,
                hint: 'E.g., Mathematics, Physics',
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppDropdownField<DepartmentEntity>(
                      label: 'Department',
                      items: schoolState.departments,
                      selectedItem: _selectedDepartmentId != null
                          ? schoolState.departments
                              .where((d) => d.id == _selectedDepartmentId)
                              .firstOrNull
                          : null,
                      onChanged: (d) =>
                          setState(() => _selectedDepartmentId = d?.id),
                      isRequired: true,
                      itemLabel: (d) => d.name,
                      itemBuilder: (d) => DropdownMenuItem<DepartmentEntity>(
                        value: d,
                        child: Text(
                          d.name,
                          style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppDropdownField<EmploymentType>(
                      label: 'Employment Type',
                      items: EmploymentType.values,
                      selectedItem: _employmentType,
                      onChanged: (v) =>
                          setState(() => _employmentType = v ?? EmploymentType.fullTime),
                      isRequired: true,
                      itemLabel: (e) => e.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              GestureDetector(
                onTap: () => _pickDate(
                  current: _employmentStartDate,
                  onPicked: (d) => setState(() => _employmentStartDate = d),
                ),
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Employment Start Date',
                    controller: TextEditingController(
                      text: _formatDate(_employmentStartDate),
                    ),
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                ),
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Save Button ──────────────────────────────────────
              AppButton(
                label: _isEditing ? 'Update Teacher' : 'Create Teacher',
                onPressed: _isSaving ? null : _saveTeacher,
                variant: AppButtonVariant.elevated,
                fullWidth: true,
                isLoading: _isSaving,
                icon: _isEditing ? Icons.save_outlined : Icons.add_rounded,
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
// HELPER WIDGETS
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
