import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/cbt_entities.dart';
import '../../providers/exam_list_provider.dart';
import '../../widgets/exam_card.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../features/cbt_engine/domain/entities/cbt_entities.dart';



// ═══════════════════════════════════════════════════════════════════════
// EXAM LIST PAGE (Teacher)
// ═══════════════════════════════════════════════════════════════════════

/// Teacher's exam list page with filter tabs, search, and responsive grid.
class ExamListPage extends ConsumerStatefulWidget {
  const ExamListPage({super.key});

  @override
  ConsumerState<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends ConsumerState<ExamListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearchMode = false;

  static const _tabs = [
    ExamStatusTab(label: 'All', status: null),
    ExamStatusTab(label: 'Draft', status: ExamStatus.draft),
    ExamStatusTab(label: 'Published', status: ExamStatus.published),
    ExamStatusTab(label: 'Active', status: ExamStatus.active),
    ExamStatusTab(label: 'Completed', status: ExamStatus.completed),
    ExamStatusTab(label: 'Archived', status: ExamStatus.archived),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load exams on init
    Future.microtask(() {
      ref.read(examListProvider.notifier).loadExams();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = _tabs[_tabController.index];
      ref.read(examListProvider.notifier).setStatusFilter(tab.status);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ExamEntity> _filterBySearch(List<ExamEntity> exams) {
    if (!_isSearchMode || _searchController.text.isEmpty) return exams;
    final query = _searchController.text.toLowerCase();
    return exams
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            (e.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(examListProvider);
    final filteredExams = _filterBySearch(state.exams);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Exams',
        isSearchMode: _isSearchMode,
        searchController: _searchController,
        onSearchToggle: () {
          setState(() => _isSearchMode = !_isSearchMode);
          if (!_isSearchMode) _searchController.clear();
        },
        onSearchChanged: (_) => setState(() {}),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          labelStyle: tt.labelLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
          ),
          unselectedLabelStyle: tt.labelLarge,
          tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
        ),
        actions: [
          // Create exam FAB in app bar
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: AppButton(
              label: 'Create',
              onPressed: () {
                // Navigate to exam builder
              },
              variant: AppButtonVariant.elevated,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(examListProvider.notifier).refresh(),
        child: state.isLoading && state.exams.isEmpty
            ? const Center(child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
            : state.error != null && state.exams.isEmpty
                ? AppErrorState.genericError(
                    message: state.error,
                    onRetry: () =>
                        ref.read(examListProvider.notifier).loadExams(),
                  )
                : filteredExams.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: AppEmptyState(
                              icon: Icons.quiz_outlined,
                              title: _isSearchMode
                                  ? 'No Matching Exams'
                                  : 'No Exams Found',
                              subtitle: _isSearchMode
                                  ? 'Try adjusting your search or filters.'
                                  : 'Create your first exam to get started.',
                              actionLabel: _isSearchMode ? null : 'Create Exam',
                              onAction: _isSearchMode
                                  ? null
                                  : () {
                                      // Navigate to exam builder
                                    },
                            ),
                          ),
                        ],
                      )
                    : _buildExamGrid(context, filteredExams, state),
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Navigate to exam builder
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Exam'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  Widget _buildExamGrid(
    BuildContext context,
    List<ExamEntity> exams,
    ExamListState state,
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
            padding: const EdgeInsets.all(Spacings.md),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: ExamCard(
                  exam: exams[index],
                  onEdit: () {},
                  onMonitor: () {},
                  onResults: () {},
                  onClone: () =>
                      ref.read(examListProvider.notifier).cloneExam(exams[index].id),
                  onArchive: () =>
                      ref.read(examListProvider.notifier).archiveExam(exams[index].id),
                  onTap: () {
                    // Navigate to exam detail
                  },
                ),
              );
            },
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(Spacings.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.6,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            return ExamCard(
              exam: exams[index],
              onEdit: () {},
              onMonitor: () {},
              onResults: () {},
              onClone: () =>
                  ref.read(examListProvider.notifier).cloneExam(exams[index].id),
              onArchive: () =>
                  ref.read(examListProvider.notifier).archiveExam(exams[index].id),
              onTap: () {
                // Navigate to exam detail
              },
            );
          },
        );
      },
    );
  }
}

class ExamStatusTab {
  const ExamStatusTab({required this.label, required this.status});
  final String label;
  final ExamStatus? status;
}
