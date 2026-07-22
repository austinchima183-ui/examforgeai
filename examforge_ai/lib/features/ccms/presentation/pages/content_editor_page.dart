import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class ContentEditorPage extends ConsumerStatefulWidget {
  const ContentEditorPage({super.key, this.contentId});

  final String? contentId;

  @override
  ConsumerState<ContentEditorPage> createState() =>
      _ContentEditorPageState();
}

class _ContentEditorPageState extends ConsumerState<ContentEditorPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _markingSchemeCtrl = TextEditingController();
  final _teacherNotesCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _markAllocationCtrl = TextEditingController();
  final _timeAllocationCtrl = TextEditingController();
  final _correctAnswerCtrl = TextEditingController();

  ContentType _contentType = ContentType.question;
  QuestionCategory _questionCategory = QuestionCategory.multipleChoice;
  DifficultyLevel _difficulty = DifficultyLevel.intermediate;
  BloomTaxonomy _bloomLevel = BloomTaxonomy.apply;
  Set<BloomTaxonomy> _selectedBloomLevels = {BloomTaxonomy.apply};
  String? _selectedSubjectId;
  String? _selectedLevelId;
  String? _selectedTopicId;
  String _sourceType = 'original';
  bool _isPastQuestion = false;
  final _pastYearCtrl = TextEditingController();
  String? _selectedExamBody;
  bool _isAiGenerated = false;
  bool _licensingDeclared = false;

  // MCQ Options
  List<_OptionItem> _options = [
    _OptionItem(label: 'A', text: '', isCorrect: true),
    _OptionItem(label: 'B', text: '', isCorrect: false),
    _OptionItem(label: 'C', text: '', isCorrect: false),
    _OptionItem(label: 'D', text: '', isCorrect: false),
  ];

  // Tags as chips
  List<String> _tags = [];
  final _tagInputCtrl = TextEditingController();

  // Learning objectives
  List<String> _learningObjectives = [];
  final _objectiveCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(educationalLevelProvider.notifier).loadEducationalLevels();
      if (widget.contentId != null) {
        ref
            .read(contentProvider.notifier)
            .loadContentById(widget.contentId!);
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _explanationCtrl.dispose();
    _markingSchemeCtrl.dispose();
    _teacherNotesCtrl.dispose();
    _tagsCtrl.dispose();
    _markAllocationCtrl.dispose();
    _timeAllocationCtrl.dispose();
    _correctAnswerCtrl.dispose();
    _pastYearCtrl.dispose();
    _tagInputCtrl.dispose();
    _objectiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(educationalLevelProvider);
    final topicState = ref.watch(topicProvider);
    final contentState = ref.watch(contentProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: widget.contentId != null ? 'Edit Content' : 'Create Content',
        actions: [
          TextButton(
              onPressed: _saveDraft, child: const Text('Save Draft')),
          const SizedBox(width: Spacings.sm),
          AppButton(
            label: 'Submit',
            onPressed: _submitForReview,
            size: AppButtonSize.small,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title *', border: OutlineInputBorder()),
            ),
            Spacings.sectionGap,

            // ── Content Type & Question Category ──────────────────
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ContentType>(
                    value: _contentType,
                    decoration: const InputDecoration(
                        labelText: 'Content Type *',
                        border: OutlineInputBorder()),
                    items: ContentType.values
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _contentType = v!),
                  ),
                ),
                if (_contentType == ContentType.question) ...[
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: DropdownButtonFormField<QuestionCategory>(
                      value: _questionCategory,
                      decoration: const InputDecoration(
                          labelText: 'Question Category',
                          border: OutlineInputBorder()),
                      items: QuestionCategory.values
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _questionCategory = v!),
                    ),
                  ),
                ],
              ],
            ),
            Spacings.sectionGap,

            // ── Subject, Level, Topic ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Select')),
                      ...subjectState.subjects.map((s) =>
                          DropdownMenuItem(
                              value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedSubjectId = v),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLevelId,
                    decoration: const InputDecoration(
                        labelText: 'Level *',
                        border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Select')),
                      ...levelState.levels.map((l) =>
                          DropdownMenuItem(
                              value: l.id, child: Text(l.name))),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedLevelId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              value: _selectedTopicId,
              decoration: const InputDecoration(
                  labelText: 'Topic/Subtopic',
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Select')),
                ...topicState.topics.map((t) => DropdownMenuItem(
                    value: t.id, child: Text(t.title))),
              ],
              onChanged: (v) => setState(() => _selectedTopicId = v),
            ),
            Spacings.sectionGap,

            // ── Difficulty & Bloom's Level ────────────────────────
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DifficultyLevel>(
                    value: _difficulty,
                    decoration: const InputDecoration(
                        labelText: 'Difficulty *',
                        border: OutlineInputBorder()),
                    items: DifficultyLevel.values
                        .map((d) => DropdownMenuItem(
                            value: d, child: Text(d.label)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _difficulty = v!),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: DropdownButtonFormField<BloomTaxonomy>(
                    value: _bloomLevel,
                    decoration: const InputDecoration(
                        labelText: "Bloom's Level *",
                        border: OutlineInputBorder()),
                    items: BloomTaxonomy.values
                        .map((b) => DropdownMenuItem(
                            value: b, child: Text(b.label)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _bloomLevel = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            Text("Bloom's Taxonomy Multi-Select",
                style: AppTypography.labelMedium!.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wSemiBold)),
            const SizedBox(height: Spacings.sm),
            BloomTaxonomySelector(
              selectedLevels: _selectedBloomLevels,
              onSelectionChanged: (levels) =>
                  setState(() => _selectedBloomLevels = levels),
            ),
            Spacings.sectionGap,

            // ── Body Text ─────────────────────────────────────────
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Content Body *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
              maxLines: 8,
            ),
            Spacings.sectionGap,

            // ── Options Editor (MCQ) ──────────────────────────────
            if (_contentType == ContentType.question &&
                (_questionCategory == QuestionCategory.multipleChoice ||
                    _questionCategory ==
                        QuestionCategory.objective)) ...[
              Text('Answer Options',
                  style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface)),
              const SizedBox(height: Spacings.sm),
              ..._options.asMap().entries.map((entry) {
                final idx = entry.key;
                final opt = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Center(
                          child: Text(opt.label,
                              style: tt.labelLarge?.copyWith(
                                  fontWeight: AppTypography.wBold,
                                  color: opt.isCorrect
                                      ? AppColors.success
                                      : cs.onSurfaceVariant)),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: opt.text),
                          decoration: InputDecoration(
                            labelText: 'Option ${opt.label}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => opt.text = v,
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      IconButton(
                        icon: Icon(
                          opt.isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: opt.isCorrect
                              ? AppColors.success
                              : cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            for (final o in _options) {
                              o.isCorrect = false;
                            }
                            _options[idx].isCorrect = true;
                            _correctAnswerCtrl.text = opt.label;
                          });
                        },
                        tooltip: 'Mark as correct answer',
                      ),
                      if (_options.length > 2)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              color: AppColors.error, size: 20),
                          onPressed: () {
                            setState(() => _options.removeAt(idx));
                          },
                        ),
                    ],
                  ),
                );
              }),
              AppButton(
                label: 'Add Option',
                onPressed: () {
                  final nextLabel = String.fromCharCode(
                      65 + _options.length);
                  setState(() {
                    _options.add(_OptionItem(
                        label: nextLabel, text: '', isCorrect: false));
                  });
                },
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                icon: Icons.add_rounded,
              ),
              Spacings.sectionGap,
            ],

            // ── Correct Answer ────────────────────────────────────
            if (_contentType == ContentType.question) ...[
              TextField(
                controller: _correctAnswerCtrl,
                decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                    border: OutlineInputBorder()),
              ),
              Spacings.sectionGap,
            ],

            // ── Step-by-step Explanation ──────────────────────────
            TextField(
              controller: _explanationCtrl,
              decoration: const InputDecoration(
                  labelText: 'Step-by-Step Explanation',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
              maxLines: 5,
            ),
            const SizedBox(height: Spacings.md),

            // ── Marking Scheme ────────────────────────────────────
            TextField(
              controller: _markingSchemeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Marking Scheme',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
              maxLines: 4,
            ),
            const SizedBox(height: Spacings.md),

            // ── Teacher Notes ─────────────────────────────────────
            TextField(
              controller: _teacherNotesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Teacher Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true),
              maxLines: 3,
            ),
            Spacings.sectionGap,

            // ── Learning Objectives ───────────────────────────────
            Text('Learning Objectives',
                style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.xs,
              children: _learningObjectives
                  .asMap()
                  .entries
                  .map((e) => Chip(
                        label: Text(e.value),
                        onDeleted: () => setState(
                            () => _learningObjectives.removeAt(e.key)),
                        deleteIconColor: cs.onSurfaceVariant,
                      ))
                  .toList(),
            ),
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _objectiveCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Add Learning Objective',
                        border: OutlineInputBorder(),
                        isDense: true),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) {
                        setState(() {
                          _learningObjectives.add(v);
                        });
                        _objectiveCtrl.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (_objectiveCtrl.text.isNotEmpty) {
                      setState(() {
                        _learningObjectives.add(_objectiveCtrl.text);
                      });
                      _objectiveCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            Spacings.sectionGap,

            // ── Tags (Chip Input) ─────────────────────────────────
            Text('Tags',
                style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.xs,
              children: _tags
                  .asMap()
                  .entries
                  .map((e) => Chip(
                        label: Text(e.value),
                        onDeleted: () =>
                            setState(() => _tags.removeAt(e.key)),
                        deleteIconColor: cs.onSurfaceVariant,
                      ))
                  .toList(),
            ),
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Add Tag',
                        border: OutlineInputBorder(),
                        isDense: true),
                    onSubmitted: (v) {
                      if (v.isNotEmpty && !_tags.contains(v)) {
                        setState(() => _tags.add(v));
                        _tagInputCtrl.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (_tagInputCtrl.text.isNotEmpty &&
                        !_tags.contains(_tagInputCtrl.text)) {
                      setState(() => _tags.add(_tagInputCtrl.text));
                      _tagInputCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            Spacings.sectionGap,

            // ── Marks & Time Allocated ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _markAllocationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Marks Allocated',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: TextField(
                    controller: _timeAllocationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Time Allocated (seconds)',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Spacings.sectionGap,

            // ── Source Type ───────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _sourceType,
              decoration: const InputDecoration(
                  labelText: 'Source Type',
                  border: OutlineInputBorder()),
              items: ['original', 'adapted', 'imported', 'ai_generated']
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _sourceType = v!),
            ),
            const SizedBox(height: Spacings.md),

            // ── Past Question Toggle ──────────────────────────────
            SwitchListTile(
              value: _isPastQuestion,
              onChanged: (v) => setState(() => _isPastQuestion = v),
              title: const Text('Past Question'),
              activeColor: cs.primary,
            ),
            if (_isPastQuestion) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pastYearCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedExamBody,
                      decoration: const InputDecoration(
                          labelText: 'Exam Body',
                          border: OutlineInputBorder()),
                      items: ['WAEC', 'NECO', 'NABTEB', 'JAMB']
                          .map((b) => DropdownMenuItem(
                              value: b, child: Text(b)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedExamBody = v),
                    ),
                  ),
                ],
              ),
            ],
            Spacings.sectionGap,

            // ── Licensing Declaration ──────────────────────────────
            Container(
              padding: Spacings.paddingCard,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _licensingDeclared,
                    onChanged: (v) =>
                        setState(() => _licensingDeclared = v ?? false),
                    activeColor: cs.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I declare that this content is original or I have the right to use it.',
                      style: AppTypography.bodySmall!
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            Spacings.sectionGap,

            // ── Action Buttons ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Save Draft',
                    onPressed: _saveDraft,
                    variant: AppButtonVariant.outlined,
                    icon: Icons.save_outlined,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppButton(
                    label: 'Submit for Review',
                    onPressed: _submitForReview,
                    variant: AppButtonVariant.tonal,
                    icon: Icons.send_rounded,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppButton(
                    label: 'Publish',
                    onPressed: _publishDirectly,
                    icon: Icons.publish_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ContentItem _buildContentItem(ContentStatus status) {
    return ContentItem(
      id: widget.contentId ?? '',
      title: _titleCtrl.text,
      contentType: _contentType,
      questionCategory: _questionCategory,
      subjectId: _selectedSubjectId ?? '',
      educationalLevelId: _selectedLevelId ?? '',
      topicId: _selectedTopicId,
      body: _bodyCtrl.text,
      difficultyLevel: _difficulty,
      bloomLevel: _bloomLevel,
      stepByStepExplanation: _explanationCtrl.text.isEmpty ? null : _explanationCtrl.text,
      markingScheme:
          _markingSchemeCtrl.text.isEmpty ? null : {'text': _markingSchemeCtrl.text},
      teacherNotes:
          _teacherNotesCtrl.text.isEmpty ? null : _teacherNotesCtrl.text,
      marksAllocated: double.tryParse(_markAllocationCtrl.text)?.toInt(),
      timeAllocatedSeconds: int.tryParse(_timeAllocationCtrl.text) != null ? int.tryParse(_timeAllocationCtrl.text)! * 60 : null,
      sourceType: _sourceType,
      isPastQuestion: _isPastQuestion,
      isAiGenerated: _isAiGenerated,
      status: status,
      version: 1,
      usageCount: 0,
      tags: _tags.isEmpty ? null : _tags,
      learningObjectiveIds:
          _learningObjectives.isEmpty ? null : _learningObjectives,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _saveDraft() {
    ref.read(contentProvider.notifier).createContent(
        _buildContentItem(ContentStatus.draft));
    Navigator.pop(context);
  }

  void _submitForReview() {
    ref.read(contentProvider.notifier).createContent(
        _buildContentItem(ContentStatus.review));
    Navigator.pop(context);
  }

  void _publishDirectly() {
    ref.read(contentProvider.notifier).createContent(
        _buildContentItem(ContentStatus.published));
    Navigator.pop(context);
  }
}

class _OptionItem {
  _OptionItem(
      {required this.label, required this.text, required this.isCorrect});

  String label;
  String text;
  bool isCorrect;
}
