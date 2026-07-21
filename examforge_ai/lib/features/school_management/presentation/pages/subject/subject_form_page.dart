import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/subject_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SUBJECT FORM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form page to create or edit a subject.
class SubjectFormPage extends ConsumerStatefulWidget {
  const SubjectFormPage({super.key, this.subject});

  /// If non-null, the form is in edit mode.
  final SubjectEntity? subject;

  @override
  ConsumerState<SubjectFormPage> createState() => _SubjectFormPageState();
}

class _SubjectFormPageState extends ConsumerState<SubjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _isCompulsory = true;
  bool _isElective = false;
  bool _isActive = true;
  bool _isSchoolSpecific = false;
  bool _isSaving = false;

  static const _categories = [
    'Science',
    'Arts',
    'Commercial',
    'Languages',
    'Mathematics',
    'Technology',
    'Social Studies',
    'Religious Studies',
    'Physical Education',
    'Vocational',
    'General',
  ];

  bool get _isEditMode => widget.subject != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final subj = widget.subject!;
      _nameController.text = subj.name;
      _codeController.text = subj.code;
      _descriptionController.text = subj.description ?? '';
      _selectedCategory = subj.category;
      _isCompulsory = subj.isCompulsory;
      _isElective = subj.isElective;
      _isActive = subj.isActive;
      _isSchoolSpecific = subj.schoolId != null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Subject' : 'New Subject',
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
                  Icons.menu_book_rounded,
                  size: 48,
                  color: cs.primary,
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  'Create a New Subject',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  'Define a subject that can be assigned to classes and teachers.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.xl),
              ],

              // ─── Subject Name ───────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  hintText: 'e.g. Mathematics, English Language',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Subject Code ───────────────────────────────────────
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code *',
                  hintText: 'e.g. MTH, ENG, PHY',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject code is required';
                  }
                  if (value.trim().length > 10) {
                    return 'Code must be 10 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Description ────────────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the subject',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: Spacings.lg),

              // ─── Category ───────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select category'),
                  ),
                  ..._categories.map(
                    (cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: Spacings.xl),

              // ─── Toggles Section ────────────────────────────────────
              Text(
                'Subject Options',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.md),

              // Compulsory / Elective
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Compulsory',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
                subtitle: Text(
                  'This subject is mandatory for all students',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                leading: Radio<bool>(
                  value: true,
                  groupValue: _isCompulsory ? true : (_isElective ? false : true),
                  onChanged: (value) {
                    setState(() {
                      _isCompulsory = true;
                      _isElective = false;
                    });
                  },
                  activeColor: cs.primary,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Elective',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
                subtitle: Text(
                  'Students can choose this subject optionally',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                leading: Radio<bool>(
                  value: false,
                  groupValue: _isCompulsory ? true : false,
                  onChanged: (value) {
                    setState(() {
                      _isCompulsory = false;
                      _isElective = true;
                    });
                  },
                  activeColor: cs.primary,
                ),
              ),
              const Divider(),
              const SizedBox(height: Spacings.sm),

              // School-specific toggle
              SwitchListTile(
                title: Text(
                  'School-Specific',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
                subtitle: Text(
                  _isSchoolSpecific
                      ? 'This subject is specific to your school'
                      : 'This subject is available across all schools',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _isSchoolSpecific,
                onChanged: (value) =>
                    setState(() => _isSchoolSpecific = value),
                activeColor: cs.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacings.md),

              // Active status
              SwitchListTile(
                title: Text(
                  'Active',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
                subtitle: Text(
                  _isActive
                      ? 'This subject is currently active'
                      : 'This subject is deactivated',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: cs.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacings.xxxl),

              // ─── Action Buttons ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label:
                          _isEditMode ? 'Update Subject' : 'Create Subject',
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
      if (_isEditMode) {
        final updatedSubject = widget.subject!.copyWith(
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategory,
          isCompulsory: _isCompulsory,
          isElective: _isElective,
          isActive: _isActive,
        );
        await ref
            .read(subjectListProvider.notifier)
            .updateSubject(updatedSubject);
      } else {
        final newSubject = SubjectEntity(
          id: '',
          name: _nameController.text.trim(),
          code: _codeController.text.trim().toUpperCase(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          schoolId: _isSchoolSpecific ? 'current-school' : null,
          category: _selectedCategory,
          isCompulsory: _isCompulsory,
          isElective: _isElective,
          isActive: _isActive,
        );
        await ref
            .read(subjectListProvider.notifier)
            .createSubject(newSubject);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Subject updated successfully'
                  : 'Subject created successfully',
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
