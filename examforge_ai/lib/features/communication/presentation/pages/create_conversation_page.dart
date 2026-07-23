import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../../domain/usecases/create_conversation_usecase.dart';
import '../providers/conversation_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CREATE CONVERSATION PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Form to create a new conversation.
///
/// Fields:
/// - Conversation type selector
/// - Name field (for group/department/class)
/// - Participant selector (searchable multi-select)
/// - Class/Department/Subject selector (for typed conversations)
/// - Create/Cancel buttons
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class CreateConversationPage extends ConsumerStatefulWidget {
  const CreateConversationPage({super.key});

  @override
  ConsumerState<CreateConversationPage> createState() => _State();
}

class _State extends ConsumerState<CreateConversationPage> {
  // ─── Controllers ────────────────────────────────────────────────────

  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  // ─── State ──────────────────────────────────────────────────────────

  ConversationType _conversationType = ConversationType.direct;
  final Set<String> _selectedParticipantIds = {};
  String? _selectedClassId;
  String? _selectedDepartmentId;
  String? _selectedSubjectId;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();

  // ─── Mock available participants (in real app, loaded from provider)
  static const _mockParticipants = [
    _Participant(id: '1', name: 'Dr. Sarah Johnson', role: 'teacher', avatar: null),
    _Participant(id: '2', name: 'Mr. James Wilson', role: 'teacher', avatar: null),
    _Participant(id: '3', name: 'Mrs. Emily Davis', role: 'teacher', avatar: null),
    _Participant(id: '4', name: 'Principal Robert Brown', role: 'admin', avatar: null),
    _Participant(id: '5', name: 'Ms. Linda Martinez', role: 'teacher', avatar: null),
    _Participant(id: '6', name: 'Mr. David Lee', role: 'teacher', avatar: null),
    _Participant(id: '7', name: 'Mrs. Patricia Taylor', role: 'parent', avatar: null),
    _Participant(id: '8', name: 'Mr. Michael Anderson', role: 'parent', avatar: null),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'New Conversation',
        actions: [
          TextButton(
            onPressed: state.isCreating ? null : _create,
            child: Text(
              'Create',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Conversation Type ────────────────────────────
                  _buildSectionLabel('Conversation Type'),
                  const SizedBox(height: Spacings.sm),
                  _buildTypeSelector(),
                  const SizedBox(height: Spacings.xl),

                  // ─── Name (for non-direct) ───────────────────────
                  if (_conversationType != ConversationType.direct) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _nameLabel(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: Spacings.xl),
                  ],

                  // ─── Class/Department/Subject selector ────────────
                  if (_conversationType == ConversationType.classChat ||
                      _conversationType == ConversationType.department) ...[
                    _buildScopedSelector(),
                    const SizedBox(height: Spacings.xl),
                  ],

                  // ─── Participant Selector ─────────────────────────
                  _buildSectionLabel('Participants'),
                  const SizedBox(height: Spacings.sm),
                  _buildSelectedParticipants(),
                  const SizedBox(height: Spacings.md),
                  _buildParticipantSearch(),
                  const SizedBox(height: Spacings.sm),
                  _buildParticipantList(),

                  const SizedBox(height: Spacings.xxl),

                  // ─── Buttons ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: state.isCreating ? null : _create,
                          child: state.isCreating
                              ? const SizedBox(width: 20, height: 20, child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small))
                              : const Text('Create'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.isCreating)
            const AppLoadingOverlay(message: 'Creating conversation…'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION LABEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TYPE SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: ConversationType.values.map((type) {
        final isSelected = _conversationType == type;
        return ChoiceChip(
          avatar: Icon(_typeIcon(type), size: Spacings.smIcon),
          label: Text(type.label),
          selected: isSelected,
          onSelected: (_) => setState(() {
            _conversationType = type;
            _selectedParticipantIds.clear();
          }),
        );
      }).toList(),
    );
  }

  IconData _typeIcon(ConversationType type) {
    switch (type) {
      case ConversationType.direct:
        return Icons.person_outline;
      case ConversationType.group:
        return Icons.group_outlined;
      case ConversationType.department:
        return Icons.business_outlined;
      case ConversationType.classChat:
        return Icons.class_outlined;
      case ConversationType.schoolWide:
        return Icons.campaign_outlined;
    }
  }

  String _nameLabel() {
    switch (_conversationType) {
      case ConversationType.group:
        return 'Group Name';
      case ConversationType.department:
        return 'Department Name';
      case ConversationType.classChat:
        return 'Class Name';
      case ConversationType.schoolWide:
        return 'Channel Name';
      default:
        return 'Name';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SCOPED SELECTOR (Class/Department/Subject)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildScopedSelector() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // In a real app, these would be loaded from providers
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_conversationType == ConversationType.classChat) ...[
          _buildSectionLabel('Class'),
          const SizedBox(height: Spacings.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedClassId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_outlined),
              hintText: 'Select class',
            ),
            items: const [
              DropdownMenuItem(value: 'class_1', child: Text('Grade 10A')),
              DropdownMenuItem(value: 'class_2', child: Text('Grade 10B')),
              DropdownMenuItem(value: 'class_3', child: Text('Grade 11A')),
            ],
            onChanged: (v) => setState(() => _selectedClassId = v),
          ),
        ],
        if (_conversationType == ConversationType.department) ...[
          _buildSectionLabel('Department'),
          const SizedBox(height: Spacings.sm),
          DropdownButtonFormField<String>(
            initialValue: _selectedDepartmentId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business_outlined),
              hintText: 'Select department',
            ),
            items: const [
              DropdownMenuItem(value: 'dept_1', child: Text('Mathematics')),
              DropdownMenuItem(value: 'dept_2', child: Text('Science')),
              DropdownMenuItem(value: 'dept_3', child: Text('English')),
              DropdownMenuItem(value: 'dept_4', child: Text('Arts')),
            ],
            onChanged: (v) => setState(() => _selectedDepartmentId = v),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PARTICIPANT SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSelectedParticipants() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_selectedParticipantIds.isEmpty) {
      return Text(
        _conversationType == ConversationType.direct
            ? 'Select a person to chat with'
            : 'Add participants',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      );
    }

    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: _selectedParticipantIds.map((id) {
        final p = _mockParticipants.firstWhere((p) => p.id == id);
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Text(p.name[0], style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer)),
          ),
          label: Text(p.name, style: tt.labelSmall),
          onDeleted: () => setState(() => _selectedParticipantIds.remove(id)),
        );
      }).toList(),
    );
  }

  Widget _buildParticipantSearch() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Search people…',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm),
      ),
      onChanged: (q) => setState(() => _searchQuery = q),
    );
  }

  Widget _buildParticipantList() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final filtered = _mockParticipants.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: Spacings.borderRadiusMd,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = filtered[i];
          final isSelected = _selectedParticipantIds.contains(p.id);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(p.name[0], style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
            ),
            title: Text(p.name, style: tt.bodyMedium),
            subtitle: Text(p.role, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: cs.primary)
                : Icon(Icons.circle_outlined, color: cs.outlineVariant),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedParticipantIds.remove(p.id);
                } else {
                  if (_conversationType == ConversationType.direct) {
                    _selectedParticipantIds.clear();
                  }
                  _selectedParticipantIds.add(p.id);
                }
              });
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CREATE
  // ═══════════════════════════════════════════════════════════════════════

  void _create() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedParticipantIds.isEmpty && _conversationType != ConversationType.schoolWide) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one participant.')));
      return;
    }

    ref.read(conversationProvider.notifier).createConversation(
      CreateConversationParams(
        type: _conversationType,
        name: _conversationType != ConversationType.direct ? _nameController.text.trim() : 'Direct Message',
        participantIds: _selectedParticipantIds.toList(),
        classId: _selectedClassId,
        departmentId: _selectedDepartmentId,
        subjectId: _selectedSubjectId,
      ),
    );

    Navigator.of(context).pop();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _Participant {
  const _Participant({
    required this.id,
    required this.name,
    required this.role,
    this.avatar,
  });

  final String id;
  final String name;
  final String role;
  final String? avatar;
}
