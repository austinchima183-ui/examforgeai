import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../routing/route_names.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/class_provider.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../features/school_management/domain/entities/school_management_entities.dart';



// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT FORM PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form page for creating or editing a school announcement.
///
/// Fields: title, content (multiline), type dropdown, priority dropdown,
/// target audience, target class selector, attachments, pin toggle,
/// expiration date. Publish or save draft.
class AnnouncementFormPage extends ConsumerStatefulWidget {
  const AnnouncementFormPage({super.key, this.announcementId});

  /// If provided, we edit an existing announcement. Otherwise, create new.
  final String? announcementId;

  @override
  ConsumerState<AnnouncementFormPage> createState() =>
      _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends ConsumerState<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // ─── Form controllers ──────────────────────────────────────────────
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  AnnouncementType _selectedType = AnnouncementType.notice;
  AnnouncementPriority _selectedPriority = AnnouncementPriority.normal;
  String _targetAudience = 'all';
  final List<String> _selectedClassIds = [];
  final List<String> _attachmentUrls = [];
  bool _isPinned = false;
  DateTime? _expirationDate;
  bool _isSaving = false;
  bool _isPublishing = false;

  bool get _isEditing => widget.announcementId != null;

  static const _audienceOptions = [
    ('all', 'Everyone'),
    ('students', 'Students'),
    ('teachers', 'Teachers'),
    ('parents', 'Parents'),
    ('specific_classes', 'Specific Classes'),
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
    _contentController.dispose();
    super.dispose();
  }

  // ─── Date Picker ───────────────────────────────────────────────────

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No expiration';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  // ─── Save ──────────────────────────────────────────────────────────

  Future<void> _saveAnnouncement({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      if (publish) {
        _isPublishing = true;
      } else {
        _isSaving = true;
      }
    });

    final announcement = AnnouncementEntity(
      id: _isEditing ? widget.announcementId! : '',
      schoolId: 'current-school',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      announcementType: _selectedType,
      priority: _selectedPriority,
      targetAudience: _targetAudience,
      targetClassIds: _targetAudience == 'specific_classes' ? _selectedClassIds : [],
      attachmentUrls: _attachmentUrls,
      isPinned: _isPinned,
      isPublished: publish,
      expiresAt: _expirationDate,
    );

    if (_isEditing) {
      await ref.read(announcementListProvider.notifier).updateAnnouncement(announcement);
    } else {
      await ref.read(announcementListProvider.notifier).createAnnouncement(announcement);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Announcement' : 'New Announcement',
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
              onPressed: _isSaving || _isPublishing
                  ? null
                  : () => _saveAnnouncement(publish: false),
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
              // ─── Content ────────────────────────────────────────────
              _FormSectionHeader(
                title: 'Content',
                icon: Icons.article_outlined,
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
                label: 'Content',
                controller: _contentController,
                isRequired: true,
                prefixIcon: Icons.text_snippet_outlined,
                maxLines: 8,
                hint: 'Write the announcement content here...',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Content is required' : null,
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Type & Priority ────────────────────────────────────
              _FormSectionHeader(
                title: 'Type & Priority',
                icon: Icons.label_outlined,
              ),
              const SizedBox(height: Spacings.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AnnouncementType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: AnnouncementType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedType = v);
                      },
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: DropdownButtonFormField<AnnouncementPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: AnnouncementPriority.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPriority = v);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacings.xxl),

              // ─── Target Audience ────────────────────────────────────
              _FormSectionHeader(
                title: 'Target Audience',
                icon: Icons.group_outlined,
              ),
              const SizedBox(height: Spacings.md),
              DropdownButtonFormField<String>(
                value: _targetAudience,
                decoration: const InputDecoration(
                  labelText: 'Audience',
                  prefixIcon: Icon(Icons.public_outlined),
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

              // ─── Class selector (when specific_classes) ─────────────
              if (_targetAudience == 'specific_classes') ...[
                const SizedBox(height: Spacings.md),
                Text(
                  'Select Classes',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.sm),
                Wrap(
                  spacing: Spacings.sm,
                  runSpacing: Spacings.sm,
                  children: classState.classes.map((cls) {
                    final isSelected = _selectedClassIds.contains(cls.id);
                    return FilterChip(
                      label: Text(cls.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedClassIds.add(cls.id);
                          } else {
                            _selectedClassIds.remove(cls.id);
                          }
                        });
                      },
                      selectedColor: cs.primary.withOpacity(0.20),
                      checkmarkColor: cs.primary,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: Spacings.xxl),

              // ─── Options ────────────────────────────────────────────
              _FormSectionHeader(
                title: 'Options',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: Spacings.md),
              SwitchListTile(
                title: const Text('Pin Announcement'),
                subtitle: const Text('Pinned announcements appear at the top'),
                value: _isPinned,
                onChanged: (v) => setState(() => _isPinned = v),
                activeColor: cs.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Spacings.md),
              GestureDetector(
                onTap: _pickExpirationDate,
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Expiration Date',
                    controller: TextEditingController(
                      text: _formatDate(_expirationDate),
                    ),
                    prefixIcon: Icons.event_outlined,
                  ),
                ),
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
                          : () => _saveAnnouncement(publish: false),
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
                          : () => _saveAnnouncement(publish: true),
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
            color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.12),
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
