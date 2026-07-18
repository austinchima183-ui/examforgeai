import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/exam_template_entities.dart';
import '../providers/exam_template_provider.dart';
import '../widgets/exam_template_card.dart';

// ═══════════════════════════════════════════════════════════════════════
// EXAM TEMPLATES PAGE (Teacher)
// ═══════════════════════════════════════════════════════════════════════

/// Teacher's exam templates page with search, category filter chips,
/// template grid, and "Save as Template" FAB.
class ExamTemplatesPage extends ConsumerStatefulWidget {
  const ExamTemplatesPage({super.key});

  @override
  ConsumerState<ExamTemplatesPage> createState() => _ExamTemplatesPageState();
}

class _ExamTemplatesPageState extends ConsumerState<ExamTemplatesPage> {
  final _searchController = TextEditingController();
  bool _isSearchMode = false;

  static const _categories = [
    _CategoryChip(label: 'All', category: null),
    _CategoryChip(label: 'School Exam', category: TemplateCategory.schoolExam),
    _CategoryChip(label: 'WAEC', category: TemplateCategory.waecPrep),
    _CategoryChip(label: 'NECO', category: TemplateCategory.necoPrep),
    _CategoryChip(label: 'JAMB', category: TemplateCategory.jambPrep),
    _CategoryChip(label: 'BECE', category: TemplateCategory.becePrep),
    _CategoryChip(label: 'Cert.', category: TemplateCategory.certification),
    _CategoryChip(label: 'Custom', category: TemplateCategory.custom),
  ];

  @override
  void initState() {
    super.initState();
    // Load templates on init
    Future.microtask(() {
      ref.read(examTemplateProvider.notifier).loadTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExamTemplateEntity> _filterBySearch(List<ExamTemplateEntity> templates) {
    if (!_isSearchMode || _searchController.text.isEmpty) return templates;
    final query = _searchController.text.toLowerCase();
    return templates
        .where((t) =>
            t.name.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(examTemplateProvider);
    final filteredTemplates = _filterBySearch(state.templates);

    // Listen for success messages
    ref.listen<ExamTemplateState>(examTemplateProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.successOf(cs.brightness),
          ),
        );
        ref.read(examTemplateProvider.notifier).clearSuccess();
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.errorOf(cs.brightness),
          ),
        );
        ref.read(examTemplateProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Exam Templates',
        isSearchMode: _isSearchMode,
        searchController: _searchController,
        searchHint: 'Search templates...',
        onSearchToggle: () {
          setState(() => _isSearchMode = !_isSearchMode);
          if (!_isSearchMode) _searchController.clear();
        },
        onSearchChanged: (_) => setState(() {}),
      ),
      body: Column(
        children: [
          // ── Category Filter Chips ────────────────────────────────────
          _buildCategoryChips(context, state),

          // ── Body Content ─────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(examTemplateProvider.notifier).refresh(),
              child: state.isLoading && state.templates.isEmpty
                  ? const Center(
                      child: AppLoadingSpinner(
                          size: AppLoadingSpinnerSize.large),
                    )
                  : state.error != null && state.templates.isEmpty
                      ? AppErrorState.genericError(
                          message: state.error,
                          onRetry: () => ref
                              .read(examTemplateProvider.notifier)
                              .loadTemplates(),
                        )
                      : filteredTemplates.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.45,
                                  child: AppEmptyState(
                                    icon: Icons.description_outlined,
                                    title: _isSearchMode
                                        ? 'No Matching Templates'
                                        : 'No Templates Yet',
                                    subtitle: _isSearchMode
                                        ? 'Try adjusting your search or filters.'
                                        : 'Save an exam as a template to reuse it later.',
                                    actionLabel: _isSearchMode
                                        ? null
                                        : 'Save as Template',
                                    onAction: _isSearchMode
                                        ? null
                                        : _onSaveAsTemplate,
                                  ),
                                ),
                              ],
                            )
                          : _buildTemplateGrid(context, filteredTemplates, state),
            ),
          ),
        ],
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _onSaveAsTemplate,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save as Template'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  // ─── Category Chips ────────────────────────────────────────────────────

  Widget _buildCategoryChips(BuildContext context, ExamTemplateState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((chip) {
            final isSelected = state.categoryFilter == chip.category;
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: FilterChip(
                selected: isSelected,
                label: Text(chip.label),
                labelStyle: tt.labelLarge?.copyWith(
                  fontWeight: isSelected
                      ? AppTypography.wSemiBold
                      : AppTypography.wMedium,
                  color: isSelected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant,
                ),
                selectedColor: cs.primary,
                checkmarkColor: cs.onPrimary,
                side: BorderSide(
                  color: isSelected
                      ? cs.primary
                      : cs.outlineVariant,
                ),
                onSelected: (_) {
                  ref
                      .read(examTemplateProvider.notifier)
                      .setCategoryFilter(
                        isSelected ? null : chip.category,
                      );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Template Grid ─────────────────────────────────────────────────────

  Widget _buildTemplateGrid(
    BuildContext context,
    List<ExamTemplateEntity> templates,
    ExamTemplateState state,
  ) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isDesktop
            ? 3
            : isTablet
                ? 2
                : 1;

        if (crossAxisCount == 1) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: ExamTemplateCard(
                  template: templates[index],
                  onUseTemplate: () => _onUseTemplate(templates[index]),
                  onDelete: () => _onDeleteTemplate(templates[index]),
                  onTap: () => _onTemplateTap(templates[index]),
                ),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(Spacings.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.5,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return ExamTemplateCard(
              template: templates[index],
              onUseTemplate: () => _onUseTemplate(templates[index]),
              onDelete: () => _onDeleteTemplate(templates[index]),
              onTap: () => _onTemplateTap(templates[index]),
            );
          },
        );
      },
    );
  }

  // ─── Action Handlers ───────────────────────────────────────────────────

  void _onSaveAsTemplate() {
    // TODO: Navigate to save-as-template dialog or page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save as Template — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onUseTemplate(ExamTemplateEntity template) {
    ref
        .read(examTemplateProvider.notifier)
        .createExamFromTemplate(template.id);
  }

  void _onTemplateTap(ExamTemplateEntity template) {
    // TODO: Navigate to template detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template: ${template.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDeleteTemplate(ExamTemplateEntity template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(examTemplateProvider.notifier)
                  .deleteTemplate(template.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chip Data ──────────────────────────────────────────────────

class _CategoryChip {
  const _CategoryChip({required this.label, required this.category});

  final String label;
  final TemplateCategory? category;
}
