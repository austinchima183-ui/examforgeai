import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../school_management/domain/entities/school_management_entities.dart';
import '../../../school_management/presentation/providers/teacher_provider.dart';
import '../../domain/entities/workspace_expansion_entities.dart';
import '../../domain/usecases/share_resource_usecase.dart';
import '../providers/collaboration_provider.dart';

/// A dialog for sharing a resource with a colleague.
///
/// Displays a search field to find teachers in the same school, permission
/// toggles (Can Edit, Can Comment, Can Download — Can View is always true),
/// an optional message, and a Share button.
class ShareResourceDialog extends ConsumerStatefulWidget {
  /// The type of the resource being shared (e.g. 'lesson_plan').
  final String resourceType;

  /// The unique ID of the resource.
  final String resourceId;

  /// Human-readable title of the resource.
  final String resourceTitle;

  const ShareResourceDialog({
    super.key,
    required this.resourceType,
    required this.resourceId,
    required this.resourceTitle,
  });

  /// Convenience method for showing this dialog.
  static Future<void> show(
    BuildContext context, {
    required String resourceType,
    required String resourceId,
    required String resourceTitle,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ShareResourceDialog(
        resourceType: resourceType,
        resourceId: resourceId,
        resourceTitle: resourceTitle,
      ),
    );
  }

  @override
  ConsumerState<ShareResourceDialog> createState() =>
      _ShareResourceDialogState();
}

class _ShareResourceDialogState extends ConsumerState<ShareResourceDialog> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  TeacherProfileEntity? _selectedTeacher;
  bool _canEdit = false;
  bool _canComment = true;
  bool _canDownload = true;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final collaborationState = ref.watch(collaborationProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.share_rounded, color: colorScheme.primary),
          const SizedBox(width: Spacings.sm),
          const Text('Share Resource'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Resource Title ───────────────────────────────────────
              Text(
                widget.resourceTitle,
                style: context.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.lg),

              // ── Search Field ─────────────────────────────────────────
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search teachers by name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: Spacings.paddingInput,
                  border: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                ),
              ),
              const SizedBox(height: Spacings.md),

              // ── Search Results ───────────────────────────────────────
              _buildTeacherList(),

              const SizedBox(height: Spacings.lg),

              // ── Selected Teacher Chip ────────────────────────────────
              if (_selectedTeacher != null)
                _buildSelectedTeacherChip(context),

              const SizedBox(height: Spacings.lg),

              // ── Permission Toggles ───────────────────────────────────
              Text(
                'Permissions',
                style: context.textTheme.titleSmall,
              ),
              const SizedBox(height: Spacings.sm),
              _buildPermissionToggles(context),

              const SizedBox(height: Spacings.lg),

              // ── Message ──────────────────────────────────────────────
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a message (optional)',
                  isDense: true,
                  contentPadding: Spacings.paddingInput,
                  border: OutlineInputBorder(
                    borderRadius: Spacings.borderRadiusMd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedTeacher == null || collaborationState.isSharing
              ? null
              : _onShare,
          child: collaborationState.isSharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Share'),
        ),
      ],
    );
  }

  // ─── Teacher List ─────────────────────────────────────────────────────

  Widget _buildTeacherList() {
    final teacherState = ref.watch(teacherListProvider);

    if (teacherState.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (teacherState.error != null) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'Error loading teachers',
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      );
    }

    final teachers = teacherState.teachers;
    if (teachers.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'No teachers found',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: teachers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          final isSelected = _selectedTeacher?.id == teacher.id;

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  context.colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                (teacher.fullName ?? '?').substring(0, 1).toUpperCase(),
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              teacher.fullName ?? 'Unknown',
              style: context.textTheme.bodyMedium,
            ),
            subtitle: teacher.departmentName != null
                ? Text(
                    teacher.departmentName!,
                    style: context.textTheme.bodySmall,
                  )
                : null,
            trailing: isSelected
                ? Icon(Icons.check_circle, color: context.colorScheme.primary)
                : null,
            onTap: () {
              setState(() {
                _selectedTeacher = isSelected ? null : teacher;
              });
            },
          );
        },
      ),
    );
  }

  // ─── Selected Teacher Chip ────────────────────────────────────────────

  Widget _buildSelectedTeacherChip(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        radius: 12,
        backgroundColor:
            context.colorScheme.primary.withValues(alpha: 0.12),
        child: Text(
          (_selectedTeacher!.fullName ?? '?').substring(0, 1).toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      label: Text(
        _selectedTeacher!.fullName ?? 'Unknown',
        style: context.textTheme.bodySmall,
      ),
      onDeleted: () {
        setState(() {
          _selectedTeacher = null;
        });
      },
      deleteIconColor: context.colorScheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // ─── Permission Toggles ──────────────────────────────────────────────

  Widget _buildPermissionToggles(BuildContext context) {
    return Column(
      children: [
        _PermissionToggle(
          label: 'Can View',
          value: true,
          enabled: false,
          onChanged: (_) {},
        ),
        _PermissionToggle(
          label: 'Can Edit',
          value: _canEdit,
          onChanged: (v) => setState(() => _canEdit = v),
        ),
        _PermissionToggle(
          label: 'Can Comment',
          value: _canComment,
          onChanged: (v) => setState(() => _canComment = v),
        ),
        _PermissionToggle(
          label: 'Can Download',
          value: _canDownload,
          onChanged: (v) => setState(() => _canDownload = v),
        ),
      ],
    );
  }

  // ─── Search Handler ──────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    // Trigger a search through the teacher provider.
    // The provider will handle debouncing internally.
    ref.read(teacherListProvider.notifier).searchTeachers(query);
  }

  // ─── Share Handler ────────────────────────────────────────────────────

  Future<void> _onShare() async {
    if (_selectedTeacher == null) return;

    await ref.read(collaborationProvider.notifier).shareResource(
          ShareResourceParams(
            resourceType: widget.resourceType,
            resourceId: widget.resourceId,
            sharedWith: _selectedTeacher!.userId,
            canEdit: _canEdit,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          ),
        );

    if (mounted) {
      final state = ref.read(collaborationProvider);
      if (state.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource shared successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to share resource'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE: Permission Toggle
// ═══════════════════════════════════════════════════════════════════════

class _PermissionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PermissionToggle({
    required this.label,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: context.textTheme.bodyMedium),
      value: value,
      onChanged: enabled ? onChanged : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: context.colorScheme.primary,
    );
  }
}
