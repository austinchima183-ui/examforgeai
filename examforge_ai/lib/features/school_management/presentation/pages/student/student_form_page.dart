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
import '../providers/student_provider.dart';
import '../providers/class_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// STUDENT FORM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form page for creating or editing a student profile.
/// Sections: Personal Info, Admission Info, Contact Info, Medical Info.
class StudentFormPage extends ConsumerStatefulWidget {
  const StudentFormPage({super.key, this.studentId});

  /// If provided, we are editing an existing student. Otherwise, creating new.
  final String? studentId;

  @override
  ConsumerState<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends ConsumerState<StudentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // ─── Personal Info Controllers ──────────────────────────────────
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _otherNamesController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  String? _passportPhotoUrl;

  // ─── Admission Info Controllers ─────────────────────────────────
  final _admissionNumberController = TextEditingController();
  String? _selectedClassId;
  DateTime? _admissionDate;

  // ─── Contact Info Controllers ───────────────────────────────────
  final _homeAddressController = TextEditingController();
  final _stateOfOriginController = TextEditingController();
  final _lgaController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Nigerian');
  final _religionController = TextEditingController();

  // ─── Medical Info Controllers ───────────────────────────────────
  final _bloodGroupController = TextEditingController();
  final _genotypeController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  final _emergencyContactRelationshipController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditing => widget.studentId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _otherNamesController.dispose();
    _admissionNumberController.dispose();
    _homeAddressController.dispose();
    _stateOfOriginController.dispose();
    _lgaController.dispose();
    _nationalityController.dispose();
    _religionController.dispose();
    _bloodGroupController.dispose();
    _genotypeController.dispose();
    _medicalConditionsController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final profile = StudentProfileEntity(
      id: _isEditing ? widget.studentId! : '',
      userId: '',
      schoolId: 'current-school',
      admissionNumber: _admissionNumberController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      passportPhotoUrl: _passportPhotoUrl,
      homeAddress: _homeAddressController.text.trim().isNotEmpty
          ? _homeAddressController.text.trim()
          : null,
      stateOfOrigin: _stateOfOriginController.text.trim().isNotEmpty
          ? _stateOfOriginController.text.trim()
          : null,
      localGovernment: _lgaController.text.trim().isNotEmpty
          ? _lgaController.text.trim()
          : null,
      nationality: _nationalityController.text.trim(),
      religion: _religionController.text.trim().isNotEmpty
          ? _religionController.text.trim()
          : null,
      admissionDate: _admissionDate,
      currentClassId: _selectedClassId,
      bloodGroup: _bloodGroupController.text.trim().isNotEmpty
          ? _bloodGroupController.text.trim()
          : null,
      genotype: _genotypeController.text.trim().isNotEmpty
          ? _genotypeController.text.trim()
          : null,
      medicalConditions: _medicalConditionsController.text.trim().isNotEmpty
          ? _medicalConditionsController.text.trim()
          : null,
      emergencyContactName: _emergencyContactNameController.text.trim().isNotEmpty
          ? _emergencyContactNameController.text.trim()
          : null,
      emergencyContactPhone: _emergencyContactPhoneController.text.trim().isNotEmpty
          ? _emergencyContactPhoneController.text.trim()
          : null,
      emergencyContactRelationship:
          _emergencyContactRelationshipController.text.trim().isNotEmpty
              ? _emergencyContactRelationshipController.text.trim()
              : null,
      fullName:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
    );

    if (_isEditing) {
      await ref.read(studentListProvider.notifier).updateStudent(profile);
    } else {
      await ref.read(studentListProvider.notifier).createStudent(profile);
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
      initialDate: current ?? DateTime(2010),
      firstDate: DateTime(1990),
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
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classState = ref.watch(classListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Student' : 'New Student',
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
              onPressed: _isSaving ? null : _saveStudent,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar placeholder
                  GestureDetector(
                    onTap: () {
                      // Pick passport photo
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(Spacings.mdRadius),
                        border: Border.all(
                          color: cs.outlineVariant,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: _passportPhotoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(Spacings.mdRadius),
                              child: Image.network(
                                _passportPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.add_a_photo_rounded,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  color: cs.onSurfaceVariant,
                                  size: Spacings.mdIcon,
                                ),
                                const SizedBox(height: Spacings.xs),
                                Text(
                                  'Photo',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'First Name',
                          controller: _firstNameController,
                          isRequired: true,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: Spacings.md),
                        AppTextField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          isRequired: true,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Other Names',
                controller: _otherNamesController,
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
                          isRequired: true,
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
                      isRequired: true,
                      itemLabel: (v) => v,
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Admission Information Section ─────────────────────
              _FormSectionHeader(
                title: 'Admission Information',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Admission Number',
                controller: _admissionNumberController,
                isRequired: true,
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'Class',
                      items: classState.classes,
                      selectedItem: _selectedClassId != null
                          ? classState.classes
                              .where((c) => c.id == _selectedClassId)
                              .firstOrNull
                          : null,
                      onChanged: (v) => setState(() => _selectedClassId = v?.id),
                      isRequired: true,
                      itemLabel: (c) => c.name,
                      itemBuilder: (c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(
                        current: _admissionDate,
                        onPicked: (d) => setState(() => _admissionDate = d),
                      ),
                      child: AbsorbPointer(
                        child: AppTextField(
                          label: 'Admission Date',
                          controller: TextEditingController(
                            text: _formatDate(_admissionDate),
                          ),
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Contact Information Section ───────────────────────
              _FormSectionHeader(
                title: 'Contact Information',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Home Address',
                controller: _homeAddressController,
                prefixIcon: Icons.home_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'State of Origin',
                      controller: _stateOfOriginController,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppTextField(
                      label: 'LGA',
                      controller: _lgaController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Nationality',
                      controller: _nationalityController,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppTextField(
                      label: 'Religion',
                      controller: _religionController,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Medical Information Section ───────────────────────
              _FormSectionHeader(
                title: 'Medical Information',
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'Blood Group',
                      items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                      selectedItem: _bloodGroupController.text.isNotEmpty
                          ? _bloodGroupController.text
                          : null,
                      onChanged: (v) {
                        if (v != null) _bloodGroupController.text = v;
                      },
                      itemLabel: (v) => v,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'Genotype',
                      items: const ['AA', 'AS', 'SS', 'AC', 'SC', 'CC'],
                      selectedItem: _genotypeController.text.isNotEmpty
                          ? _genotypeController.text
                          : null,
                      onChanged: (v) {
                        if (v != null) _genotypeController.text = v;
                      },
                      itemLabel: (v) => v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Medical Conditions',
                controller: _medicalConditionsController,
                prefixIcon: Icons.healing_outlined,
                maxLines: 2,
                hint: 'E.g., Asthma, Allergies...',
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Emergency Contact Name',
                controller: _emergencyContactNameController,
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Emergency Phone',
                      controller: _emergencyContactPhoneController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'Relationship',
                      items: const ['Parent', 'Guardian', 'Sibling', 'Other'],
                      selectedItem: _emergencyContactRelationshipController
                              .text.isNotEmpty
                          ? _emergencyContactRelationshipController.text
                          : null,
                      onChanged: (v) {
                        if (v != null) {
                          _emergencyContactRelationshipController.text = v;
                        }
                      },
                      itemLabel: (v) => v,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Save Button ──────────────────────────────────────
              AppButton(
                label: _isEditing ? 'Update Student' : 'Create Student',
                onPressed: _isSaving ? null : _saveStudent,
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
