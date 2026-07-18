import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/school_management_entities.dart';
import '../providers/document_provider.dart';
import '../providers/class_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT UPLOAD PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Upload form for documents.
///
/// Fields: title, description, document type dropdown, category, file
/// picker, tags input, public/private toggle, target audience, associate
/// with student (optional). Upload progress indicator.
class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() =>
      _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // ─── Form controllers ──────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();

  DocumentType _selectedDocType = DocumentType.general;
  bool _isPublic = false;
  String _targetAudience = 'all';
  String? _selectedClassId;
  String? _associatedStudentId;
  String? _selectedFileName;
  String? _selectedFilePath;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _isSaving = false;

  final List<String> _tags = [];

  static const _audienceOptions = [
    ('all', 'Everyone'),
    ('students', 'Students Only'),
    ('teachers', 'Teachers Only'),
    ('parents', 'Parents Only'),
    ('specific_class', 'Specific Class'),
  ];

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
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // ─── File Picker ───────────────────────────────────────────────────

  Future<void> _pickFile() async {
    // In production, use file_picker package.
    // Simulating file selection:
    setState(() {
      _selectedFileName = 'example_document.pdf';
      _selectedFilePath = '/path/to/example_document.pdf';
    });
  }

  // ─── Add Tag ───────────────────────────────────────────────────────

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  // ─── Upload ────────────────────────────────────────────────────────

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    // Simulate upload progress
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _uploadProgress = i / 10);
    }

    setState(() => _isUploading = false);

    // Create document entity and save
    setState(() => _isSaving = true);

    final document = DocumentEntity(
      id: '',
      schoolId: 'current-school',
      title: _titleController.text.trim(),
      fileUrl: _selectedFilePath ?? '',
      fileName: _selectedFileName ?? '',
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      documentType: _selectedDocType,
      category: _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : null,
      tags: _tags,
      isPublic: _isPublic,
      targetAudience: _targetAudience,
    );

    await ref.read(documentListProvider.notifier).createDocument(document);

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final classState = ref.watch(classListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Document',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── File Selection ──────────────────────────────────────
              _FormSectionHeader(
                title: 'File',
                icon: Icons.upload_file_rounded,
              ),
              const SizedBox(height: Spacings.md),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacings.xl),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    border: Border.all(
                      color: cs.outlineVariant,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFileName != null
                            ? Icons.insert_drive_file_rounded
                            : Icons.cloud_upload_outlined,
                        size: Spacings.xlIcon,
                        color: _selectedFileName != null ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: Spacings.md),
                      Text(
                        _selectedFileName ?? 'Click to select a file',
                        style: tt.bodyLarge?.copyWith(
                          color: _selectedFileName != null ? cs.onSurface : cs.onSurfaceVariant,
                          fontWeight: _selectedFileName != null
                              ? AppTypography.wSemiBold
                              : AppTypography.wRegular,
                        ),
                      ),
                      if (_selectedFileName == null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacings.xs),
                          child: Text(
                            'PDF, DOC, XLS, Images (max 25 MB)',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ─── Upload Progress ─────────────────────────────────────
              if (_isUploading) ...[
                const SizedBox(height: Spacings.md),
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: cs.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    const SizedBox(height: Spacings.sm),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: Spacings.xxl),

              // ─── Document Details ───────────────────────────────────
              _FormSectionHeader(
                title: 'Document Details',
                icon: Icons.description_outlined,
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
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                hint: 'Brief description of the document...',
              ),
              const SizedBox(height: Spacings.md),
              DropdownButtonFormField<DocumentType>(
                value: _selectedDocType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: DocumentType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedDocType = v);
                },
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Category',
                controller: _categoryController,
                prefixIcon: Icons.label_outlined,
                hint: 'E.g., Academics, Sports, Administration...',
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Tags ───────────────────────────────────────────────
              _FormSectionHeader(
                title: 'Tags',
                icon: Icons.tag_rounded,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Add Tag',
                      controller: _tagsController,
                      prefixIcon: Icons.add_circle_outline_rounded,
                      hint: 'Type a tag and press Add',
                    ),
                  ),
                  const SizedBox(width: Spacings.sm),
                  AppButton(
                    label: 'Add',
                    onPressed: _addTag,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.small,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: Spacings.sm),
                Wrap(
                  spacing: Spacings.sm,
                  runSpacing: Spacings.sm,
                  children: _tags.map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close_rounded, size: Spacings.smIcon),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      )).toList(),
                ),
              ],

              const SizedBox(height: Spacings.xxl),

              // ─── Access & Visibility ────────────────────────────────
              _FormSectionHeader(
                title: 'Access & Visibility',
                icon: Icons.visibility_outlined,
              ),
              const SizedBox(height: Spacings.md),
              SwitchListTile(
                title: const Text('Public Document'),
                subtitle: const Text('Visible to all users; otherwise restricted'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                activeColor: cs.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacings.md),
              DropdownButtonFormField<String>(
                value: _targetAudience,
                decoration: const InputDecoration(
                  labelText: 'Target Audience',
                  prefixIcon: Icon(Icons.group_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _audienceOptions
                    .map((opt) => DropdownMenuItem(
                          value: opt.$1,
                          child: Text(opt.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _targetAudience = v);
                },
              ),

              // ─── Class selector (when specific_class) ───────────────
              if (_targetAudience == 'specific_class') ...[
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<String>(
                  value: _selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Select Class',
                    prefixIcon: Icon(Icons.class_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: classState.classes
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedClassId = v),
                ),
              ],

              const SizedBox(height: Spacings.xxl),

              // ─── Associate with Student (optional) ──────────────────
              _FormSectionHeader(
                title: 'Associate Student (Optional)',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: Spacings.md),
              AppTextField(
                label: 'Student ID or Name',
                controller: TextEditingController(),
                prefixIcon: Icons.search_rounded,
                hint: 'Search for a student to link this document...',
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Upload Button ──────────────────────────────────────
              AppButton(
                label: 'Upload Document',
                onPressed: _isUploading || _isSaving ? null : _uploadDocument,
                variant: AppButtonVariant.elevated,
                fullWidth: true,
                isLoading: _isUploading || _isSaving,
                icon: Icons.upload_rounded,
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
