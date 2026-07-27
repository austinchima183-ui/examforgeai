import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../providers/assignment_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// List page for assignments. Features filter tabs by status, search,
/// pull-to-refresh, and a FAB to create a new assignment.
class AssignmentListPage extends ConsumerStatefulWidget {
  const AssignmentListPage({super.key});

  @override
  ConsumerState<AssignmentListPage> createState() =>
      _AssignmentListPageState();
}

class _AssignmentListPageState extends ConsumerState<AssignmentListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearchMode = false;

  static const _tabs = [
    _AssignmentStatusTab(label: 'All', status: null),
    _AssignmentStatusTab(label: 'Draft', status: AssignmentStatus.draft),
    _AssignmentStatusTab(
        label: 'Published', status: AssignmentStatus.published,),
    _AssignmentStatusTab(label: 'Closed', status: AssignmentStatus.closed),
    _AssignmentStatusTab(label: 'Graded', status: AssignmentStatus.graded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    Future.microtask(() {
      ref.read(assignmentProvider.notifier).loadAssignments();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = _tabs[_tabController.index];
      final filter = ref.read(assignmentProvider).filter.copyWith(
            isPublished: tab.status == AssignmentStatus.published
                ? true
                : tab.status == AssignmentStatus.draft
                    ? false
                    : null,
          );
      ref.read(assignmentProvider.notifier).setFilter(filter);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<WorkspaceAssignmentEntity> _filterBySearch(
    List<WorkspaceAssignmentEntity> assignments,
  ) {
    if (!_isSearchMode || _searchController.text.isEmpty) return assignments;
    final query = _searchController.text.toLowerCase();
    return assignments
        .where((a) =>
            a.title.toLowerCase().contains(query) ||
            a.subject.toLowerCase().contains(query) ||
            (a.className?.toLowerCase().contains(query) ?? false),)
        .toList();
  }

  List<WorkspaceAssignmentEntity> _filterByStatus(
    List<WorkspaceAssignmentEntity> assignments,
  ) {
    final tabIndex = _tabController.index;
    final status = _tabs[tabIndex].status;
    if (status == null) return assignments;
    return assignments
        .where((a) => a.assignmentStatus == status)
        .toList();
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(assignmentProvider);

    final filteredByStatus = _filterByStatus(state.assignments);
    final filteredAssignments = _filterBySearch(filteredByStatus);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Assignments',
        isSearchMode: _isSearchMode,
        searchController: _searchController,
        searchHint: 'Search assignments…',
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
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: AppButton(
              label: 'New',
              onPressed: () => context.push(RouteNames.assignmentGenerator),
              variant: AppButtonVariant.elevated,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(assignmentProvider.notifier).loadAssignments(),
        child: state.isLoading && state.assignments.isEmpty
            ? const Center(
                child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
              )
            : state.error != null && state.assignments.isEmpty
                ? AppErrorState.genericError(
                    message: state.error,
                    onRetry: () =>
                        ref.read(assignmentProvider.notifier).loadAssignments(),
                  )
                : filteredAssignments.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: AppEmptyState(
                              icon: Icons.assignment_outlined,
                              title: _isSearchMode
                                  ? 'No Matching Assignments'
                                  : 'No Assignments Found',
                              subtitle: _isSearchMode
                                  ? 'Try adjusting your search or filters.'
                                  : 'Create your first assignment to get started.',
                              actionLabel: _isSearchMode
                                  ? null
                                  : 'New Assignment',
                              onAction: _isSearchMode
                                  ? null
                                  : () => context
                                      .push(RouteNames.assignmentGenerator),
                            ),
                          ),
                        ],
                      )
                    : _buildAssignmentList(context, filteredAssignments, state),
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(RouteNames.assignmentGenerator),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Assignment'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  // ─── Assignment List Builder ──────────────────────────────────────────

  Widget _buildAssignmentList(
    BuildContext context,
    List<WorkspaceAssignmentEntity> assignments,
    AssignmentState state,
  ) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            isDesktop ? 3 : isTablet ? 2 : 1;

        if (crossAxisCount == 1) {
          return ListView.builder(
            padding: const EdgeInsets.all(Spacings.md),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: _AssignmentCard(
                  assignment: assignments[index],
                  formatDate: _formatDate,
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
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            return _AssignmentCard(
              assignment: assignments[index],
              formatDate: _formatDate,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ASSIGNMENT CARD
// ═══════════════════════════════════════════════════════════════════════

/// Card displaying assignment summary: title, subject, class, status badge,
/// deadline, total marks, and a "Generate Questions" button.
class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.formatDate,
  });

  final WorkspaceAssignmentEntity assignment;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      onTap: () {
        // Navigate to assignment detail / generator with this assignment
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: title + status badge ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              _StatusBadge(status: assignment.assignmentStatus),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ── Subject & Class ─────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.book_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                assignment.subject,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (assignment.className != null) ...[
                const SizedBox(width: Spacings.md),
                Icon(Icons.class_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                const SizedBox(width: Spacings.xs),
                Text(
                  assignment.className!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ── Deadline & Total Marks ──────────────────────────────────
          Row(
            children: [
              if (assignment.deadline != null) ...[
                Icon(Icons.calendar_today_outlined,
                    size: Spacings.smIcon, color: cs.onSurfaceVariant,),
                const SizedBox(width: Spacings.xs),
                Text(
                  formatDate(assignment.deadline!),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: Spacings.md),
              ],
              Icon(Icons.score_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${assignment.totalMarks.toInt()} marks',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (assignment.isAiGenerated) ...[
                const SizedBox(width: Spacings.md),
                Icon(Icons.auto_awesome_rounded,
                    size: Spacings.smIcon, color: cs.tertiary,),
              ],
            ],
          ),
          const Spacer(),

          // ── Generate Questions Button ───────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: GenerateQuestionsButton(
              resourceType: 'assignment',
              resourceId: assignment.id,
              resourceName: assignment.title,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════

/// A small coloured badge showing the assignment status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final isDark = context.isDarkMode;

    final (bgColor, fgColor) = switch (status) {
      AssignmentStatus.draft => (
          cs.onSurfaceVariant.withValues(alpha: isDark ? 0.25 : 0.12),
          cs.onSurfaceVariant,
        ),
      AssignmentStatus.published => (
          cs.primary.withValues(alpha: isDark ? 0.25 : 0.12),
          cs.primary,
        ),
      AssignmentStatus.closed => (
          cs.error.withValues(alpha: isDark ? 0.25 : 0.12),
          cs.error,
        ),
      AssignmentStatus.graded => (
          cs.tertiary.withValues(alpha: isDark ? 0.25 : 0.12),
          cs.tertiary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fgColor,
              fontWeight: AppTypography.wSemiBold,
            ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASS
// ═══════════════════════════════════════════════════════════════════════

class _AssignmentStatusTab {
  const _AssignmentStatusTab({required this.label, required this.status});
  final String label;
  final AssignmentStatus? status;
}
