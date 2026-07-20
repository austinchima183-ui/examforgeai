import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class TopicManagementPage extends ConsumerStatefulWidget {
  const TopicManagementPage({super.key});

  @override
  ConsumerState<TopicManagementPage> createState() =>
      _TopicManagementPageState();
}

class _TopicManagementPageState extends ConsumerState<TopicManagementPage> {
  String? _selectedSubjectId;
  String? _selectedLevelId;
  bool _showCurriculumTree = false;
  final _objectiveCtrl = TextEditingController();

  @override
  void dispose() {
    _objectiveCtrl.dispose();
    super.dispose();
  }

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
    final topicState = ref.watch(topicProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(educationalLevelProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Topic Management',
        actions: [
          AppIconButton(
            icon: Icons.account_tree_rounded,
            onPressed: () =>
                setState(() => _showCurriculumTree = !_showCurriculumTree),
            tooltip: _showCurriculumTree
                ? 'List View'
                : 'Curriculum Tree View',
            variant: _showCurriculumTree
                ? AppIconButtonVariant.tonal
                : AppIconButtonVariant.standard,
          ),
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: _showCreateTopicDialog,
            tooltip: 'Add Topic',
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject and Level selectors
          Padding(
            padding: Spacings.paddingScreen,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSubjectId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Select Subject')),
                      ...subjectState.subjects.map((s) =>
                          DropdownMenuItem(
                              value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedSubjectId = v);
                      if (v != null) {
                        ref
                            .read(topicProvider.notifier)
                            .loadTopics(subjectId: v);
                        if (_showCurriculumTree) {
                          ref
                              .read(topicProvider.notifier)
                              .loadCurriculumTree(v);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedLevelId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Select Level')),
                      ...levelState.levels.map((l) =>
                          DropdownMenuItem(
                              value: l.id, child: Text(l.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedLevelId = v);
                      ref.read(topicProvider.notifier).loadTopics(
                        subjectId: _selectedSubjectId,
                        educationalLevelId: v,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Curriculum tree view toggle indicator
          if (_showCurriculumTree)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.lg, vertical: Spacings.sm),
              color: cs.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(Icons.account_tree_rounded,
                      size: Spacings.smIcon, color: cs.primary),
                  const SizedBox(width: Spacings.sm),
                  Text(
                    'Curriculum Tree View',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
            ),
          // Topic tree / list
          Expanded(
            child: topicState.isLoading && topicState.topics.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : topicState.error != null
                    ? AppErrorState(
                        message: topicState.error,
                        onRetry: () => ref
                            .read(topicProvider.notifier)
                            .loadTopics(subjectId: _selectedSubjectId),
                      )
                    : topicState.topics.isEmpty
                        ? AppEmptyState.noData(
                            subtitle: _selectedSubjectId == null
                                ? 'Select a subject to view topics'
                                : 'No topics found for this subject',
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(topicProvider.notifier)
                                .loadTopics(
                                    subjectId: _selectedSubjectId),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.lg),
                              itemCount: topicState.topics.length,
                              itemBuilder: (context, index) {
                                final topic = topicState.topics[index];
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    TopicTreeNode(
                                      topic: topic,
                                      depth: 0,
                                      onEdit: () =>
                                          _showEditTopicDialog(topic),
                                      onDelete: () =>
                                          _confirmDeleteTopic(topic),
                                      onAddSubtopic: () =>
                                          _showCreateSubtopicDialog(
                                              topic.id),
                                    ),
                                    // Learning objectives under each topic
                                    if (topic.learningObjectives !=
            null &&
                                        topic.learningObjectives!
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: Spacings.xxl,
                                            bottom: Spacings.sm),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                    Icons
                                                        .flag_outlined,
                                                    size: 14,
                                                    color: cs.primary),
                                                const SizedBox(
                                                    width: Spacings.xs),
                                                Text(
                                                    'Learning Objectives',
                                                    style: tt
                                                        .labelSmall
                                                        ?.copyWith(
                                                      color: cs.primary,
                                                      fontWeight:
                                                          AppTypography
                                                              .wSemiBold,
                                                    )),
                                              ],
                                            ),
                                            const SizedBox(
                                                height: Spacings.xs),
                                            ...topic
                                                .learningObjectives!
                                                .map((obj) =>
                                                    LearningObjectiveChip(
                                                        objective: obj)),
                                          ],
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _showCreateTopicDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final sortOrderCtrl = TextEditingController(text: '0');
    final objectives = <String>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Topic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Topic Name *',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: Spacings.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: durationCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Est. Duration (min)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: TextField(
                          controller: sortOrderCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.md),
                // Learning objectives
                Text('Learning Objectives',
                    style: AppTypography.labelMedium.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: Theme.of(context).primaryColor)),
                const SizedBox(height: Spacings.sm),
                ...objectives.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.xs),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(e.value,
                                  style: AppTypography.bodySmall)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setDialogState(
                                  () => objectives.removeAt(e.key));
                            },
                          ),
                        ],
                      ),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: _objectiveCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Add Objective',
                              border: OutlineInputBorder(),
                              isDense: true),
                          onSubmitted: (v) {
                            if (v.isNotEmpty) {
                              setDialogState(() {
                                objectives.add(v);
                              });
                              _objectiveCtrl.clear();
                            }
                          }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (_objectiveCtrl.text.isNotEmpty) {
                          setDialogState(() {
                            objectives.add(_objectiveCtrl.text);
                          });
                          _objectiveCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
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
                ref.read(topicProvider.notifier).createTopic(Topic(
                  id: '',
                  title: nameCtrl.text,
                  subjectId: _selectedSubjectId ?? '',
                  educationalLevelId: _selectedLevelId ?? '',
                  curriculumId: '',
                  code: '',
                  description: descCtrl.text.isEmpty ? null : descCtrl.text,
                  sortOrder: int.tryParse(sortOrderCtrl.text) ?? 0,
                  estimatedDurationMinutes:
                      int.tryParse(durationCtrl.text),
                  depthLevel: 0,
                  isActive: true,
                  learningObjectives:
                      objectives.isEmpty ? null : objectives,
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

  void _showEditTopicDialog(Topic topic) {
    final nameCtrl = TextEditingController(text: topic.title);
    final descCtrl =
        TextEditingController(text: topic.description ?? '');
    final durationCtrl = TextEditingController(
        text: '${topic.estimatedDurationMinutes ?? ''}');
    final sortOrderCtrl =
        TextEditingController(text: '${topic.sortOrder}');
    final objectives = List<String>.from(topic.learningObjectives ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Topic'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Topic Name',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: Spacings.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: durationCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Est. Duration (min)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: Spacings.md),
                    Expanded(
                      child: TextField(
                          controller: sortOrderCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.md),
                Text('Learning Objectives',
                    style: AppTypography.labelMedium.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: Theme.of(context).primaryColor)),
                const SizedBox(height: Spacings.sm),
                ...objectives.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacings.xs),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(e.value,
                                  style: AppTypography.bodySmall)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              setDialogState(
                                  () => objectives.removeAt(e.key));
                            },
                          ),
                        ],
                      ),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: _objectiveCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Add Objective',
                              border: OutlineInputBorder(),
                              isDense: true),
                          onSubmitted: (v) {
                            if (v.isNotEmpty) {
                              setDialogState(() {
                                objectives.add(v);
                              });
                              _objectiveCtrl.clear();
                            }
                          }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (_objectiveCtrl.text.isNotEmpty) {
                          setDialogState(() {
                            objectives.add(_objectiveCtrl.text);
                          });
                          _objectiveCtrl.clear();
                        }
                      },
                    ),
                  ],
                ),
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
                ref.read(topicProvider.notifier).updateTopic(Topic(
                  id: topic.id,
                  title: nameCtrl.text,
                  subjectId: topic.subjectId,
                  educationalLevelId: topic.educationalLevelId,
                  curriculumId: topic.curriculumId,
                  code: topic.code,
                  description: descCtrl.text.isEmpty ? null : descCtrl.text,
                  sortOrder: int.tryParse(sortOrderCtrl.text) ?? topic.sortOrder,
                  estimatedDurationMinutes:
                      int.tryParse(durationCtrl.text),
                  depthLevel: topic.depthLevel,
                  isActive: topic.isActive,
                  learningObjectives:
                      objectives.isEmpty ? null : objectives,
                  createdAt: topic.createdAt,
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

  void _showCreateSubtopicDialog(String topicId) {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final sortOrderCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Subtopic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subtopic Name *',
                    border: OutlineInputBorder())),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: durationCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Est. Duration (min)',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: TextField(
                      controller: sortOrderCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Sort Order',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Create',
            onPressed: () {
              ref.read(topicProvider.notifier).createSubtopic(Subtopic(
                id: '',
                topicId: topicId,
                title: nameCtrl.text,
                code: '',
                sortOrder: int.tryParse(sortOrderCtrl.text) ?? 0,
                estimatedDurationMinutes:
                    int.tryParse(durationCtrl.text),
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text(
            'Are you sure you want to delete "${topic.title}"? All subtopics will also be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Delete',
            onPressed: () {
              ref.read(topicProvider.notifier).deleteTopic(topic.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
