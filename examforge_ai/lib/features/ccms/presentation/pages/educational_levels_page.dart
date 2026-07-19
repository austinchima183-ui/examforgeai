import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class EducationalLevelsPage extends ConsumerStatefulWidget {
  const EducationalLevelsPage({super.key});

  @override
  ConsumerState<EducationalLevelsPage> createState() =>
      _EducationalLevelsPageState();
}

class _EducationalLevelsPageState
    extends ConsumerState<EducationalLevelsPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  EducationalLevelCategory? _filterCategory;
  late TabController _tabController;
  final Map<String, TextEditingController> _customNameControllers = {};
  final Map<String, bool> _localEnabledState = {};

  static const _categoryTabs = EducationalLevelCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categoryTabs.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(educationalLevelProvider.notifier).loadEducationalLevels();
      ref.read(educationalLevelProvider.notifier).loadSchoolLevels('school_1');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final ctrl in _customNameControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(educationalLevelProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final filteredLevels = state.levels.where((l) {
      if (_filterCategory != null &&
          l.levelCategory != _filterCategory) return false;
      if (_searchQuery.isNotEmpty &&
          !l.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    final grouped = <EducationalLevelCategory, List<EducationalLevel>>{};
    for (final level in filteredLevels) {
      grouped.putIfAbsent(level.levelCategory, () => []).add(level);
    }

    return Scaffold(
      appBar: AppAppBar(
        title: 'Educational Levels',
        isSearchMode: _searchQuery.isNotEmpty,
        searchHint: 'Search levels…',
        onSearchToggle: () => setState(() => _searchQuery = ''),
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: _categoryTabs
              .map((c) => Tab(text: c.label))
              .toList(),
        ),
      ),
      body: state.isLoading && state.levels.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null
              ? AppErrorState(
                  message: state.error,
                  onRetry: () => ref
                      .read(educationalLevelProvider.notifier)
                      .loadEducationalLevels(),
                )
              : state.levels.isEmpty
                  ? AppEmptyState.noData(
                      subtitle: 'No educational levels found')
                  : TabBarView(
                      controller: _tabController,
                      children: _categoryTabs.map((category) {
                        final levels = grouped[category] ?? [];
                        return _buildCategorySection(
                          context,
                          category,
                          levels,
                          state.schoolLevels,
                          cs,
                          tt,
                        );
                      }).toList(),
                    ),
      bottomNavigationBar: _buildSaveButton(cs),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    EducationalLevelCategory category,
    List<EducationalLevel> levels,
    List<SchoolLevelConfiguration> schoolLevels,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (levels.isEmpty) {
      return AppEmptyState.noData(
        subtitle: 'No levels in ${category.label}',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(educationalLevelProvider.notifier)
          .loadEducationalLevels(),
      child: ListView.builder(
        padding: Spacings.paddingScreen,
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final config = schoolLevels
              .where((c) => c.educationalLevelId == level.id)
              .firstOrNull;
          final isEnabled = _localEnabledState[level.id] ??
              (config?.isEnabled ?? false);

          // Initialize custom name controller if needed
          if (!_customNameControllers.containsKey(level.id)) {
            _customNameControllers[level.id] = TextEditingController(
              text: config?.customName ?? level.name,
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: LevelCategoryCard(
              category: category,
              levels: [level],
              schoolLevels: schoolLevels,
              onToggleLevel: (levelId) {
                setState(() {
                  _localEnabledState[levelId] = !isEnabled;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs) {
    return SafeArea(
      child: Padding(
        padding: Spacings.paddingScreen,
        child: AppButton(
          label: 'Save Configuration',
          onPressed: _saveConfiguration,
          fullWidth: true,
          icon: Icons.save_rounded,
        ),
      ),
    );
  }

  void _saveConfiguration() {
    final state = ref.read(educationalLevelProvider);
    for (final level in state.levels) {
      final isEnabled = _localEnabledState[level.id] ??
          (state.schoolLevels
                  .where((c) => c.educationalLevelId == level.id)
                  .firstOrNull
                  ?.isEnabled ??
              false);
      final customName = _customNameControllers[level.id]?.text;
      ref
          .read(educationalLevelProvider.notifier)
          .configureSchoolLevel(
            'school_1',
            level.id,
            isEnabled,
            customName,
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved successfully')),
    );
  }
}
