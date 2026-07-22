import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class SubjectsManagementPage extends ConsumerStatefulWidget {
  const SubjectsManagementPage({super.key});

  @override
  ConsumerState<SubjectsManagementPage> createState() =>
      _SubjectsManagementPageState();
}

class _SubjectsManagementPageState
    extends ConsumerState<SubjectsManagementPage> {
  String? _selectedLevelId;
  String? _selectedGroup;
  SubjectType? _subjectTypeFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(educationalLevelProvider.notifier).loadEducationalLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(educationalLevelProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    var filtered = subjectState.subjects.where((s) {
      if (_searchQuery.isNotEmpty &&
          !s.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !s.code.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedGroup != null && s.subjectGroup != _selectedGroup) {
        return false;
      }
      if (_subjectTypeFilter != null) {
        if (_subjectTypeFilter == SubjectType.core && !s.isCore) return false;
        if (_subjectTypeFilter == SubjectType.elective && !s.isElective) {
          return false;
        }
        if (_subjectTypeFilter == SubjectType.vocational && !s.isVocational) {
          return false;
        }
      }
      return true;
    }).toList();

    final groups = subjectState.subjects
        .map((s) => s.subjectGroup)
        .where((g) => g?.isNotEmpty ?? false)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Subjects',
        isSearchMode: _searchQuery.isNotEmpty,
        searchHint: 'Search subjects…',
        onSearchToggle: () => setState(() => _searchQuery = ''),
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _showCreateDialog,
            tooltip: 'Create Subject',
          ),
        ],
      ),
      body: subjectState.isLoading && subjectState.subjects.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : subjectState.error != null
              ? AppErrorState(
                  message: subjectState.error,
                  onRetry: () =>
                      ref.read(subjectProvider.notifier).loadSubjects(),
                )
              : Column(
                  children: [
                    // Filters row
                    Padding(
                      padding: Spacings.paddingScreen,
                      child: Column(
                        children: [
                          // Level category filter at top
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Level Category',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedLevelId,
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('All Levels')),
                              ...levelState.levels.map((l) =>
                                  DropdownMenuItem(
                                      value: l.id, child: Text(l.name))),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedLevelId = v);
                              ref
                                  .read(subjectProvider.notifier)
                                  .loadSubjects(educationalLevelId: v);
                            },
                          ),
                          const SizedBox(height: Spacings.md),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Group',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedGroup,
                                  items: [
                                    const DropdownMenuItem(
                                        value: null,
                                        child: Text('All Groups')),
                                    ...groups.map((g) => DropdownMenuItem(
                                        value: g!, child: Text(g!))),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedGroup = v),
                                ),
                              ),
                              const SizedBox(width: Spacings.md),
                              Expanded(
                                child:
                                    DropdownButtonFormField<SubjectType?>(
                                  decoration: const InputDecoration(
                                    labelText: 'Type',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _subjectTypeFilter,
                                  items: [
                                    const DropdownMenuItem(
                                        value: null,
                                        child: Text('All Types')),
                                    ...SubjectType.values.map((t) =>
                                        DropdownMenuItem(
                                            value: t,
                                            child: Text(t.label))),
                                  ],
                                  onChanged: (v) => setState(
                                      () => _subjectTypeFilter = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Subject list
                    Expanded(
                      child: filtered.isEmpty
                          ? AppEmptyState.noResults(
                              subtitle: 'No subjects match your filters',
                              onAction: () => setState(() {
                                _searchQuery = '';
                                _selectedGroup = null;
                                _subjectTypeFilter = null;
                              }),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.lg),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: Spacings.sm),
                                child: SubjectCard(
                                  subject: filtered[index],
                                  onTap: () {},
                                  onEdit: () =>
                                      _showEditDialog(filtered[index]),
                                  onDelete: () =>
                                      _confirmDelete(filtered[index]),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final groupCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var type = SubjectType.core;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name *', border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Code *', border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: groupCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Subject Group',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<SubjectType>(
                  value: type,
                  decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder()),
                  items: SubjectType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: Spacings.md),
                if (_selectedLevelId != null)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Level', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Select Level')),
                    ],
                    onChanged: (_) {},
                  ),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Create',
              onPressed: () {
                ref.read(subjectProvider.notifier).createSubject(Subject(
                  id: '',
                  name: nameCtrl.text,
                  code: codeCtrl.text,
                  subjectGroup: groupCtrl.text,
                  curriculumId: '',
                  isCore: type == SubjectType.core,
                  isElective: type == SubjectType.elective,
                  isVocational: type == SubjectType.vocational,
                  educationalLevelId: _selectedLevelId ?? '',
                  sortOrder: 0,
                  isActive: true,
                  isCustom: true,
                  description:
                      descCtrl.text.isEmpty ? null : descCtrl.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Subject subject) {
    final nameCtrl = TextEditingController(text: subject.name);
    final codeCtrl = TextEditingController(text: subject.code);
    final groupCtrl = TextEditingController(text: subject.subjectGroup);
    final descCtrl =
        TextEditingController(text: subject.description ?? '');
    var type = SubjectType.fromSubject(subject);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Code', border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: groupCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Subject Group',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<SubjectType>(
                  value: type,
                  decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder()),
                  items: SubjectType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Save',
              onPressed: () {
                ref.read(subjectProvider.notifier).updateSubject(subject.id, Subject(
                  id: subject.id,
                  name: nameCtrl.text,
                  code: codeCtrl.text,
                  subjectGroup: groupCtrl.text,
                  isCore: type == SubjectType.core,
                  isElective: type == SubjectType.elective,
                  isVocational: type == SubjectType.vocational,
                  curriculumId: subject.curriculumId,
                  educationalLevelId: subject.educationalLevelId,
                  sortOrder: subject.sortOrder,
                  isActive: subject.isActive,
                  isCustom: subject.isCustom,
                  description: descCtrl.text.isEmpty
                      ? null
                      : descCtrl.text,
                  createdAt: subject.createdAt,
                  updatedAt: DateTime.now(),
                ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Are you sure you want to delete "${subject.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Delete',
            onPressed: () {
              ref.read(subjectProvider.notifier).deleteSubject(subject.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
