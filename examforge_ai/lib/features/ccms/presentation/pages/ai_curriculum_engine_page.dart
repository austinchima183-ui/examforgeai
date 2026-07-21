import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class AiCurriculumEnginePage extends ConsumerStatefulWidget {
  const AiCurriculumEnginePage({super.key});

  @override
  ConsumerState<AiCurriculumEnginePage> createState() =>
      _AiCurriculumEnginePageState();
}

class _AiCurriculumEnginePageState
    extends ConsumerState<AiCurriculumEnginePage> {
  String? _selectedSchoolId;
  String? _selectedSubjectId;
  String? _selectedLevelId;
  String? _selectedCurriculumId;
  DifficultyLevel _difficultyPreference = DifficultyLevel.intermediate;
  Set<BloomTaxonomy> _selectedBloomLevels = {
    BloomTaxonomy.apply,
    BloomTaxonomy.analyze
  };
  Map<QuestionCategory, double> _questionTypeDistribution = {
    QuestionCategory.multipleChoice: 0.4,
    QuestionCategory.theory: 0.3,
    QuestionCategory.fillInBlank: 0.15,
    QuestionCategory.trueFalse: 0.15,
  };
  String _languageStyle = 'age_appropriate';
  String _contentTone = 'academic';
  String _culturalContext = 'nigerian';
  double _qualityThreshold = 70;
  double _autoApproveThreshold = 90;
  int _maxQuestionsPerGeneration = 10;
  bool _includeExplanations = true;
  bool _includeMarkingSchemes = true;
  bool _includeTeacherNotes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(educationalLevelProvider.notifier).loadEducationalLevels();
      ref.read(curriculumProvider.notifier).loadCurricula();
      ref.read(aiCurriculumProvider.notifier).loadGenerationRules();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiCurriculumProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(educationalLevelProvider);
    final curriculumState = ref.watch(curriculumProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(title: 'AI Curriculum Engine'),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Configuration ──────────────────────────────────────
            Text('Configuration',
                style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.md),

            // School selector (if super admin)
            DropdownButtonFormField<String>(
              value: _selectedSchoolId,
              decoration: const InputDecoration(
                  labelText: 'School (Super Admin)',
                  border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select School')),
                const DropdownMenuItem(value: 'school_1', child: Text('Demo School')),
              ],
              onChanged: (v) => setState(() => _selectedSchoolId = v),
            ),
            const SizedBox(height: Spacings.md),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    decoration: const InputDecoration(
                        labelText: 'Subject *', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select')),
                      ...subjectState.subjects.map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name))),
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
                        labelText: 'Level *', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select')),
                      ...levelState.levels.map((l) =>
                          DropdownMenuItem(value: l.id, child: Text(l.name))),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedLevelId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              value: _selectedCurriculumId,
              decoration: const InputDecoration(
                  labelText: 'Curriculum', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select')),
                ...curriculumState.curricula.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) =>
                  setState(() => _selectedCurriculumId = v),
            ),
            Spacings.sectionGap,

            // ── Difficulty Preference ──────────────────────────────
            Text('Difficulty Preference',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold)),
            const SizedBox(height: Spacings.sm),
            DropdownButtonFormField<DifficultyLevel>(
              value: _difficultyPreference,
              decoration:
                  const InputDecoration(border: OutlineInputBorder()),
              items: DifficultyLevel.values
                  .map((d) =>
                      DropdownMenuItem(value: d, child: Text(d.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _difficultyPreference = v!),
            ),
            Spacings.sectionGap,

            // ── Bloom's Taxonomy Multi-Selector ────────────────────
            Text("Bloom's Taxonomy Levels",
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold)),
            const SizedBox(height: Spacings.sm),
            BloomTaxonomySelector(
              selectedLevels: _selectedBloomLevels,
              onSelectionChanged: (levels) =>
                  setState(() => _selectedBloomLevels = levels),
            ),
            Spacings.sectionGap,

            // ── Question Type Distribution ─────────────────────────
            Text('Question Type Distribution',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold)),
            const SizedBox(height: Spacings.sm),
            ..._questionTypeDistribution.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.sm),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 120,
                          child: Text(entry.key.label,
                              style: tt.bodyMedium)),
                      Expanded(
                        child: Slider(
                          value: entry.value,
                          min: 0,
                          max: 1,
                          divisions: 20,
                          label: '${(entry.value * 100).round()}%',
                          onChanged: (v) => setState(
                              () => _questionTypeDistribution[entry.key] = v),
                        ),
                      ),
                      SizedBox(
                          width: 50,
                          child: Text('${(entry.value * 100).round()}%',
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant))),
                    ],
                  ),
                )),
            Spacings.sectionGap,

            // ── Language Style & Content Tone ──────────────────────
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _languageStyle,
                    decoration: const InputDecoration(
                        labelText: 'Language Style',
                        border: OutlineInputBorder()),
                    items: [
                      'age_appropriate',
                      'formal',
                      'casual',
                    ]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _languageStyle = v!),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _contentTone,
                    decoration: const InputDecoration(
                        labelText: 'Content Tone',
                        border: OutlineInputBorder()),
                    items: ['academic', 'friendly', 'neutral']
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _contentTone = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            TextField(
              decoration: InputDecoration(
                labelText: 'Cultural Context',
                border: const OutlineInputBorder(),
                hintText: _culturalContext,
              ),
              onChanged: (v) => _culturalContext = v.isEmpty ? 'nigerian' : v,
            ),
            Spacings.sectionGap,

            // ── Quality Thresholds ────────────────────────────────
            Text('Quality Thresholds',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold)),
            const SizedBox(height: Spacings.sm),
            Row(children: [
              Text('Quality: ', style: tt.bodyMedium),
              Expanded(
                child: Slider(
                  value: _qualityThreshold,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_qualityThreshold.round()}',
                  onChanged: (v) =>
                      setState(() => _qualityThreshold = v),
                ),
              ),
              Text('${_qualityThreshold.round()}',
                  style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold)),
            ]),
            Row(children: [
              Text('Auto-Approve: ', style: tt.bodyMedium),
              Expanded(
                child: Slider(
                  value: _autoApproveThreshold,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_autoApproveThreshold.round()}',
                  onChanged: (v) =>
                      setState(() => _autoApproveThreshold = v),
                ),
              ),
              Text('${_autoApproveThreshold.round()}',
                  style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold)),
            ]),
            Spacings.sectionGap,

            // ── Max Questions Per Generation ──────────────────────
            Row(
              children: [
                Text('Max Questions: ',
                    style: tt.bodyMedium),
                const SizedBox(width: Spacings.md),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (_maxQuestionsPerGeneration > 1) {
                      setState(() => _maxQuestionsPerGeneration--);
                    }
                  },
                ),
                Text('$_maxQuestionsPerGeneration',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wBold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (_maxQuestionsPerGeneration < 50) {
                      setState(() => _maxQuestionsPerGeneration++);
                    }
                  },
                ),
              ],
            ),
            Spacings.sectionGap,

            // ── Toggle Options ────────────────────────────────────
            SwitchListTile(
              value: _includeExplanations,
              onChanged: (v) =>
                  setState(() => _includeExplanations = v),
              title: const Text('Include Explanations'),
              subtitle: const Text(
                  'Generate step-by-step explanations with each question'),
              activeColor: cs.primary,
            ),
            SwitchListTile(
              value: _includeMarkingSchemes,
              onChanged: (v) =>
                  setState(() => _includeMarkingSchemes = v),
              title: const Text('Include Marking Schemes'),
              subtitle:
                  const Text('Generate marking schemes for each question'),
              activeColor: cs.primary,
            ),
            SwitchListTile(
              value: _includeTeacherNotes,
              onChanged: (v) =>
                  setState(() => _includeTeacherNotes = v),
              title: const Text('Include Teacher Notes'),
              subtitle: const Text(
                  'Generate teacher notes and pedagogical guidance'),
              activeColor: cs.primary,
            ),
            Spacings.sectionGap,

            // ── Generation Rules ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Generation Rules',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold)),
                AppButton(
                  label: 'Add Rule',
                  onPressed: _showAddRuleDialog,
                  icon: Icons.add_rounded,
                  size: AppButtonSize.small,
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            if (aiState.generationRules.isEmpty)
              Text('No generation rules configured',
                  style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant))
            else
              ...aiState.generationRules.map((rule) => Card(
                    child: ListTile(
                      title: Text(rule.ruleName),
                      subtitle: Text(rule.conditions?.toString() ?? rule.ruleType),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: rule.isActive,
                            onChanged: (_) {},
                            activeColor: cs.primary,
                          ),
                          AppIconButton(
                            icon: Icons.edit_outlined,
                            onPressed: () =>
                                _showEditRuleDialog(rule),
                            variant: AppIconButtonVariant.standard,
                            size: AppButtonSize.small,
                          ),
                        ],
                      ),
                    ),
                  )),
            Spacings.sectionGap,

            // ── Save & Test Buttons ──────────────────────────────
            AppButton(
              label: 'Save Configuration',
              onPressed: _saveConfiguration,
              fullWidth: true,
              icon: Icons.save_rounded,
            ),
            const SizedBox(height: Spacings.md),
            AppButton(
              label: 'Test Generation',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Test generation will run with current configuration')),
                );
              },
              icon: Icons.play_arrow_rounded,
              fullWidth: true,
              variant: AppButtonVariant.outlined,
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfiguration() {
    ref.read(aiCurriculumProvider.notifier).upsertConfig(AiCurriculumConfig(
      id: '',
      schoolId: _selectedSchoolId ?? 'school_1',
      subjectId: _selectedSubjectId ?? '',
      educationalLevelId: _selectedLevelId ?? '',
      curriculumId: _selectedCurriculumId ?? '',
      preferredDifficulty: _difficultyPreference,
      preferredBloomLevels: _selectedBloomLevels.toList(),
      questionTypeDistribution: _questionTypeDistribution
          .map((k, v) => MapEntry(k.value, v)),
      languageStyle: _languageStyle,
      contentTone: _contentTone,
      culturalContext: _culturalContext,
      qualityThreshold: _qualityThreshold,
      autoApproveThreshold: _autoApproveThreshold,
      maxQuestionsPerGeneration: _maxQuestionsPerGeneration,
      includeExplanations: _includeExplanations,
      includeMarkingSchemes: _includeMarkingSchemes,
      includeTeacherNotes: _includeTeacherNotes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved')),
    );
  }

  void _showAddRuleDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final conditionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Generation Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Rule Name *',
                      border: OutlineInputBorder())),
              const SizedBox(height: Spacings.md),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder()),
                  maxLines: 3),
              const SizedBox(height: Spacings.md),
              TextField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Condition (e.g., "difficulty >= intermediate")',
                      border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Add',
            onPressed: () {
              ref.read(aiCurriculumProvider.notifier).createGenerationRule(
                    AiGenerationRule(
                      id: '',
                      educationalLevelId: _selectedLevelId ?? '',
                      subjectId: _selectedSubjectId ?? '',
                      ruleName: nameCtrl.text,
                      ruleType: 'content_generation',
                      conditions: conditionCtrl.text.isEmpty
                          ? null
                          : {'expression': conditionCtrl.text},
                      actions: descCtrl.text.isEmpty
                          ? null
                          : {'description': descCtrl.text},
                      isActive: true,
                      priority: 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditRuleDialog(AiGenerationRule rule) {
    final nameCtrl = TextEditingController(text: rule.ruleName);
    final descCtrl =
        TextEditingController(text: rule.conditions?.toString() ?? '');
    final conditionCtrl =
        TextEditingController(text: rule.conditions?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Generation Rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Rule Name',
                      border: OutlineInputBorder())),
              const SizedBox(height: Spacings.md),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder()),
                  maxLines: 3),
              const SizedBox(height: Spacings.md),
              TextField(
                  controller: conditionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Condition',
                      border: OutlineInputBorder())),
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
              ref.read(aiCurriculumProvider.notifier).updateGenerationRule(
                    rule.id,
                    AiGenerationRule(
                      id: rule.id,
                      educationalLevelId: rule.educationalLevelId,
                      subjectId: rule.subjectId,
                      ruleName: nameCtrl.text,
                      ruleType: rule.ruleType,
                      conditions: conditionCtrl.text.isEmpty
                          ? null
                          : {'expression': conditionCtrl.text},
                      actions: descCtrl.text.isEmpty
                          ? null
                          : {'description': descCtrl.text},
                      isActive: rule.isActive,
                      priority: rule.priority,
                      createdAt: rule.createdAt,
                      updatedAt: DateTime.now(),
                    ),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
