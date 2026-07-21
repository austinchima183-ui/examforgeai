import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../providers/prompt_template_provider.dart';
import '../widgets/ai_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI PROMPTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Prompt Management System page with list of PromptTemplateCard widgets,
/// filter by prompt type, create new template FAB, and template editor
/// dialog/bottom sheet.
///
/// ```dart
/// AiPromptsPage()
/// ```
class AiPromptsPage extends ConsumerStatefulWidget {
  const AiPromptsPage({super.key});

  @override
  ConsumerState<AiPromptsPage> createState() => _AiPromptsPageState();
}

class _AiPromptsPageState extends ConsumerState<AiPromptsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(promptTemplateProvider.notifier).loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promptTemplateProvider);
    final notifier = ref.read(promptTemplateProvider.notifier);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Prompt Management',
        actions: [
          PopupMenuButton<PromptType?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by Type',
            onSelected: (type) {
              notifier.setFilter(type);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem<PromptType?>(
                value: null,
                child: Text('All Types'),
              ),
              ...PromptType.values.map((type) => PopupMenuItem<PromptType?>(
                    value: type,
                    child: Text(type.label),
                  )),
            ],
          ),
        ],
      ),
      body: _buildBody(state, notifier),
      floatingActionButton: AppFloatingActionButton(
        label: 'New Template',
        icon: Icons.add_rounded,
        extended: context.isDesktop || context.isTablet,
        onPressed: () => _showTemplateEditor(context, notifier),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────

  Widget _buildBody(
    PromptTemplateState state,
    PromptTemplateNotifier notifier,
  ) {
    if (state.isLoading && state.templates.isEmpty) {
      return const Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large));
    }

    if (state.error != null && state.templates.isEmpty) {
      return AppErrorState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load templates',
        message: state.error,
        onRetry: () => notifier.loadTemplates(),
      );
    }

    if (state.templates.isEmpty) {
      return AppEmptyState(
        icon: Icons.description_outlined,
        title: 'No Prompt Templates',
        subtitle:
            'Create your first prompt template to get started with AI generation.',
        actionLabel: 'Create Template',
        onAction: () => _showTemplateEditor(context, notifier),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.loadTemplates(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          Spacings.lg, Spacings.lg, Spacings.lg, Spacings.xxl + 56,
        ),
        itemCount: state.templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.md),
        itemBuilder: (context, index) {
          final template = state.templates[index];
          return PromptTemplateCard(
            template: template,
            onTap: () => _showTemplateEditor(
              context,
              notifier,
              template: template,
            ),
            onEdit: () => _showTemplateEditor(
              context,
              notifier,
              template: template,
            ),
            onDuplicate: () => _duplicateTemplate(template, notifier),
            onDelete: () => _confirmDelete(template.id, notifier),
          );
        },
      ),
    );
  }

  // ── Template Editor Dialog ──────────────────────────────────────────

  Future<void> _showTemplateEditor(
    BuildContext context,
    PromptTemplateNotifier notifier, {
    PromptTemplateEntity? template,
  }) async {
    final isEditing = template != null;
    final nameController = TextEditingController(text: template?.name ?? '');
    final descController =
        TextEditingController(text: template?.description ?? '');
    final systemPromptController =
        TextEditingController(text: template?.systemPrompt ?? '');
    final userPromptController =
        TextEditingController(text: template?.userPromptTemplate ?? '');
    final outputFormatController = TextEditingController(
      text: template?.outputFormat?.toString() ?? '',
    );

    var selectedType = template?.promptType ?? PromptType.questionGeneration;
    var selectedProvider = template?.provider;
    var selectedBloom = template?.bloomLevel;
    var chainOfThought = template?.chainOfThought ?? false;
    final variables = List<PromptVariable>.from(template?.variables ?? []);
    final fewShotExamples = List<FewShotExample>.from(
      template?.fewShotExamples ?? [],
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(Spacings.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacings.lg),

                      // Title
                      Row(
                        children: [
                          Text(
                            isEditing ? 'Edit Template' : 'New Template',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          AppIconButton(
                            icon: Icons.close_rounded,
                            onPressed: () => Navigator.of(ctx).pop(),
                            variant: AppIconButtonVariant.standard,
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.lg),

                      // Form
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name
                              AppTextField(
                                controller: nameController,
                                label: 'Template Name',
                                hint: 'e.g., WAEC Biology MCQ Generator',
                                isRequired: true,
                                prefixIcon: Icons.label_outline_rounded,
                              ),
                              const SizedBox(height: Spacings.md),

                              // Description
                              AppTextField(
                                controller: descController,
                                label: 'Description',
                                hint: 'What does this template do?',
                                maxLines: 2,
                              ),
                              const SizedBox(height: Spacings.md),

                              // Type + Provider row
                              Row(
                                children: [
                                  Expanded(
                                    child: AppDropdownField<PromptType>(
                                      label: 'Type',
                                      items: PromptType.values,
                                      selectedItem: selectedType,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(
                                              () => selectedType = val);
                                        }
                                      },
                                      itemLabel: (t) => t.label,
                                    ),
                                  ),
                                  const SizedBox(width: Spacings.md),
                                  Expanded(
                                    child: AppDropdownField<AiProvider>(
                                      label: 'Provider',
                                      items: AiProvider.values,
                                      selectedItem: selectedProvider,
                                      onChanged: (val) {
                                        setModalState(
                                            () => selectedProvider = val);
                                      },
                                      itemLabel: (p) => p.displayName,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacings.md),

                              // Bloom level
                              AppDropdownField<BloomTaxonomy>(
                                label: 'Bloom Level',
                                items: BloomTaxonomy.values,
                                selectedItem: selectedBloom,
                                onChanged: (val) {
                                  setModalState(() => selectedBloom = val);
                                },
                                itemLabel: (b) => b.label,
                              ),
                              const SizedBox(height: Spacings.md),

                              // Chain of thought
                              SwitchListTile(
                                title: Text(
                                  'Chain of Thought',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  'Enable step-by-step reasoning in the prompt',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                value: chainOfThought,
                                onChanged: (val) {
                                  setModalState(() => chainOfThought = val);
                                },
                                activeColor: context.colorScheme.primary,
                              ),
                              const SizedBox(height: Spacings.md),

                              // System prompt
                              Text(
                                'System Prompt',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: AppTypography.wSemiBold,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: Spacings.sm),
                              AppTextField(
                                controller: systemPromptController,
                                hint: 'You are an expert question generator…',
                                maxLines: 6,
                                minLines: 4,
                              ),
                              const SizedBox(height: Spacings.md),

                              // User prompt template
                              Text(
                                'User Prompt Template',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: AppTypography.wSemiBold,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: Spacings.sm),
                              AppTextField(
                                controller: userPromptController,
                                hint:
                                    'Generate {{num_questions}} questions about {{topic}}…',
                                maxLines: 6,
                                minLines: 4,
                              ),
                              const SizedBox(height: Spacings.sm),
                              Text(
                                'Use {{variable_name}} for dynamic placeholders',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: Spacings.md),

                              // Variables list
                              Row(
                                children: [
                                  Text(
                                    'Variables',
                                    style:
                                        context.textTheme.titleSmall?.copyWith(
                                      fontWeight: AppTypography.wSemiBold,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  AppIconButton(
                                    icon: Icons.add_rounded,
                                    onPressed: () {
                                      setModalState(() {
                                        variables.add(const PromptVariable(
                                          name: 'new_variable',
                                          description: 'New variable',
                                        ));
                                      });
                                    },
                                    variant: AppIconButtonVariant.tonal,
                                    size: AppButtonSize.small,
                                    tooltip: 'Add variable',
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacings.sm),
                              if (variables.isEmpty)
                                Text(
                                  'No variables defined',
                                  style:
                                      context.textTheme.bodySmall?.copyWith(
                                    color:
                                        context.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              else
                                ...variables.map((v) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: Spacings.sm),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: Spacings.sm,
                                              vertical: Spacings.xs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.colorScheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Spacings.xs),
                                            ),
                                            child: Text(
                                              '{{${v.name}}}',
                                              style: context
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: context
                                                    .colorScheme.primary,
                                                fontWeight:
                                                    AppTypography.wSemiBold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              width: Spacings.sm),
                                          Expanded(
                                            child: Text(
                                              v.description ?? v.name,
                                              style: context
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: context
                                                    .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          AppIconButton(
                                            icon: Icons.delete_outline_rounded,
                                            onPressed: () {
                                              setModalState(() {
                                                variables.remove(v);
                                              });
                                            },
                                            variant:
                                                AppIconButtonVariant.standard,
                                            size: AppButtonSize.small,
                                            color: AppColors.errorOf(
                                                context
                                                    .colorScheme.brightness),
                                          ),
                                        ],
                                      ),
                                    )),

                              const SizedBox(height: Spacings.md),

                              // Few-shot examples
                              Row(
                                children: [
                                  Text(
                                    'Few-Shot Examples',
                                    style:
                                        context.textTheme.titleSmall?.copyWith(
                                      fontWeight: AppTypography.wSemiBold,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                  const Spacer(),
                                  AppIconButton(
                                    icon: Icons.add_rounded,
                                    onPressed: () {
                                      setModalState(() {
                                        fewShotExamples.add(const FewShotExample(
                                          input: {'question': 'Example input'},
                                          output: {
                                            'answer': 'Example output'
                                          },
                                        ));
                                      });
                                    },
                                    variant: AppIconButtonVariant.tonal,
                                    size: AppButtonSize.small,
                                    tooltip: 'Add example',
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spacings.sm),
                              if (fewShotExamples.isEmpty)
                                Text(
                                  'No examples defined',
                                  style:
                                      context.textTheme.bodySmall?.copyWith(
                                    color:
                                        context.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              else
                                ...fewShotExamples.asMap().entries.map(
                                    (entry) {
                                  final idx = entry.key;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: Spacings.sm),
                                    child: AppCard(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Example ${idx + 1}',
                                              style: context
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                color: context
                                                    .colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          AppIconButton(
                                            icon:
                                                Icons.delete_outline_rounded,
                                            onPressed: () {
                                              setModalState(() {
                                                fewShotExamples
                                                    .removeAt(idx);
                                              });
                                            },
                                            variant:
                                                AppIconButtonVariant.standard,
                                            size: AppButtonSize.small,
                                            color: AppColors.errorOf(context
                                                .colorScheme.brightness),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              const SizedBox(height: Spacings.xl),

                              // Save button
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  label: isEditing
                                      ? 'Update Template'
                                      : 'Create Template',
                                  onPressed: () => _saveTemplate(
                                    context: ctx,
                                    notifier: notifier,
                                    isEditing: isEditing,
                                    existingTemplate: template,
                                    name: nameController.text,
                                    description: descController.text,
                                    promptType: selectedType,
                                    provider: selectedProvider,
                                    bloomLevel: selectedBloom,
                                    chainOfThought: chainOfThought,
                                    systemPrompt:
                                        systemPromptController.text,
                                    userPrompt: userPromptController.text,
                                    variables: variables,
                                    fewShotExamples: fewShotExamples,
                                  ),
                                  variant: AppButtonVariant.elevated,
                                  size: AppButtonSize.large,
                                  icon: isEditing
                                      ? Icons.save_rounded
                                      : Icons.add_rounded,
                                  isLoading: state.isSaving,
                                ),
                              ),
                              const SizedBox(height: Spacings.xxl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── Save Template ───────────────────────────────────────────────────

  void _saveTemplate({
    required BuildContext context,
    required PromptTemplateNotifier notifier,
    required bool isEditing,
    required PromptTemplateEntity? existingTemplate,
    required String name,
    required String description,
    required PromptType promptType,
    required AiProvider? provider,
    required BloomTaxonomy? bloomLevel,
    required bool chainOfThought,
    required String systemPrompt,
    required String userPrompt,
    required List<PromptVariable> variables,
    required List<FewShotExample> fewShotExamples,
  }) {
    if (name.trim().isEmpty || systemPrompt.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and system prompt are required')),
      );
      return;
    }

    final now = DateTime.now();

    if (isEditing && existingTemplate != null) {
      final updated = existingTemplate.copyWith(
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        promptType: promptType,
        provider: provider,
        bloomLevel: bloomLevel,
        chainOfThought: chainOfThought,
        systemPrompt: systemPrompt.trim(),
        userPromptTemplate: userPrompt.trim(),
        variables: variables,
        fewShotExamples: fewShotExamples,
        updatedAt: now,
      );
      notifier.updateTemplate(updated);
    } else {
      final newTemplate = PromptTemplateEntity(
        id: 'tpl_${now.millisecondsSinceEpoch}',
        name: name.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        promptType: promptType,
        provider: provider,
        bloomLevel: bloomLevel,
        chainOfThought: chainOfThought,
        systemPrompt: systemPrompt.trim(),
        userPromptTemplate: userPrompt.trim(),
        variables: variables,
        fewShotExamples: fewShotExamples,
        isActive: true,
        isDefault: false,
        version: 1,
        createdAt: now,
        updatedAt: now,
      );
      notifier.createTemplate(newTemplate);
    }

    Navigator.of(context).pop();
  }

  // ── Duplicate Template ─────────────────────────────────────────────

  Future<void> _duplicateTemplate(
    PromptTemplateEntity template,
    PromptTemplateNotifier notifier,
  ) async {
    final now = DateTime.now();
    final duplicate = template.copyWith(
      id: 'tpl_${now.millisecondsSinceEpoch}',
      name: '${template.name} (Copy)',
      isDefault: false,
      usageCount: 0,
      qualityScore: null,
      successRate: null,
      createdAt: now,
      updatedAt: now,
    );
    await notifier.createTemplate(duplicate);
  }

  // ── Confirm Delete ──────────────────────────────────────────────────

  Future<void> _confirmDelete(
    String templateId,
    PromptTemplateNotifier notifier,
  ) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Template?',
      message:
          'This action cannot be undone. The template will be permanently deleted.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      await notifier.deleteTemplate(templateId);
    }
  }
}
