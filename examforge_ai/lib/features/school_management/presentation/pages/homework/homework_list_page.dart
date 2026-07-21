import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_search_bar.dart';
import '../../../../../routing/route_names.dart';
import '../../../../../shared/models/user_role.dart';
import '../../../../../shared/providers/auth_state_provider.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/homework_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/subject_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Displays a filterable, searchable list of homework items.
///
/// * Teacher view: FAB to create homework, publish action per item.
/// * Student view: shows own submission status badge.
class HomeworkListPage extends ConsumerStatefulWidget {
  const HomeworkListPage({super.key});

  @override
  ConsumerState<HomeworkListPage> createState() => _HomeworkListPageState();
}

class _HomeworkListPageState extends ConsumerState<HomeworkListPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  late TabController _tabController;

  // ─── Filter state ──────────────────────────────────────────────────
  String? _selectedClassId;
  String? _selectedSubjectId;
  HomeworkStatus? _statusFilter;

  /// Whether the current user has the teacher role.
  bool get _isTeacher => ref.read(resolvedUserRoleProvider) == UserRole.teacher;

  static const _statusTabs = <HomeworkStatus?>[
    null, // All
    HomeworkStatus.published,
    HomeworkStatus.draft,
    HomeworkStatus.closed,
    HomeworkStatus.graded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(homeworkListProvider.notifier).loadHomework(
            schoolId: 'current-school',
          );
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
      ref.read(subjectListProvider.notifier).loadSubjects(schoolId: 'current-school');
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final status = _statusTabs[_tabController.index];
      setState(() => _statusFilter = status);
      ref.read(homeworkListProvider.notifier).setStatusFilter(status);
      ref.read(homeworkListProvider.notifier).loadHomework(
            schoolId: 'current-school',
            status: status,
            classId: _selectedClassId,
            subjectId: _selectedSubjectId,
          );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Future: load more
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ─── Colour helpers ────────────────────────────────────────────────

  Color _statusColor(HomeworkStatus status) {
    return switch (status) {
      HomeworkStatus.draft => AppColors.info,
      HomeworkStatus.published => const Color(0xFF3B82F6),
      HomeworkStatus.closed => AppColors.warning,
      HomeworkStatus.graded => AppColors.success,
    };
  }

  String _statusLabel(HomeworkStatus status) => status.label;

  Color _subjectBadgeColor() => AppColors.seed;

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(homeworkListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Homework',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() => _isSearchMode = !_isSearchMode);
              if (!_isSearchMode) {
                _searchController.clear();
                ref.read(homeworkListProvider.notifier).loadHomework(
                      schoolId: 'current-school',
                    );
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search homework',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter homework',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              if (_isSearchMode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  child: AppSearchBar(
                    hint: 'Search homework by title...',
                    controller: _searchController,
                    onChanged: (query) {
                      // Future: search
                    },
                  ),
                ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Published'),
                  Tab(text: 'Draft'),
                  Tab(text: 'Closed'),
                  Tab(text: 'Graded'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeworkListProvider.notifier).loadHomework(
              schoolId: 'current-school',
              status: _statusFilter,
              classId: _selectedClassId,
              subjectId: _selectedSubjectId,
            ),
        child: _buildBody(context, state),
      ),
      floatingActionButton: _isTeacher
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to homework form
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Homework'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            )
          : null,
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, HomeworkListState state) {
    if (state.isLoading && state.homeworkList.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && state.homeworkList.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(homeworkListProvider.notifier).loadHomework(
              schoolId: 'current-school',
            ),
      );
    }

    if (state.homeworkList.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          AppEmptyState(
            icon: Icons.assignment_outlined,
            title: _isSearchMode ? 'No Matching Homework' : 'No Homework Yet',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Create the first homework assignment.',
            actionLabel: _isSearchMode ? null : 'Create Homework',
            onAction: _isSearchMode
                ? null
                : () {
                    // Navigate to homework form
                  },
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: state.homeworkList.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _HomeworkCard(
            homework: state.homeworkList[index],
            statusColor: _statusColor,
            statusLabel: _statusLabel,
            subjectBadgeColor: _subjectBadgeColor(),
            isTeacher: _isTeacher,
            onTap: () {
              // Navigate to homework detail
            },
            onPublish: _isTeacher
                ? (id) {
                    ref.read(homeworkListProvider.notifier).publishHomework(id);
                  }
                : null,
          ),
        );
      },
    );
  }

  // ─── Filter bottom sheet ───────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    final classState = ref.read(classListProvider);
    final subjectState = ref.read(subjectListProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Homework',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Class dropdown
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Classes'),
                  ),
                  ...classState.classes.map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedClassId = value);
                  setModalState(() => _selectedClassId = value);
                },
              ),
              const SizedBox(height: Spacings.md),
              // Subject dropdown
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Subjects'),
                  ),
                  ...subjectState.subjects.map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedSubjectId = value);
                  setModalState(() => _selectedSubjectId = value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedClassId = null;
                          _selectedSubjectId = null;
                          _statusFilter = null;
                          _tabController.animateTo(0);
                        });
                        setModalState(() {
                          _selectedClassId = null;
                          _selectedSubjectId = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppButton(
                      label: 'Apply',
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(homeworkListProvider.notifier).loadHomework(
                              schoolId: 'current-school',
                              classId: _selectedClassId,
                              subjectId: _selectedSubjectId,
                              status: _statusFilter,
                            );
                      },
                      variant: AppButtonVariant.elevated,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + Spacings.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HOMEWORK CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _HomeworkCard extends StatelessWidget {
  const _HomeworkCard({
    required this.homework,
    required this.statusColor,
    required this.statusLabel,
    required this.subjectBadgeColor,
    this.isTeacher = false,
    this.onTap,
    this.onPublish,
  });

  final HomeworkEntity homework;
  final Color Function(HomeworkStatus) statusColor;
  final String Function(HomeworkStatus) statusLabel;
  final Color subjectBadgeColor;
  final bool isTeacher;
  final VoidCallback? onTap;
  final void Function(String homeworkId)? onPublish;

  String _formatDate(DateTime? date) {
    if (date == null) return 'No deadline';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _isOverdue =>
      homework.deadline != null && homework.deadline!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = statusColor(homework.status);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top row: title + status badge ──────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  homework.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacings.sm),
              _StatusBadge(color: color, label: statusLabel(homework.status)),
            ],
          ),
          const SizedBox(height: Spacings.sm),

          // ─── Subject badge + Class name ─────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: subjectBadgeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  homework.subjectName ?? 'Subject',
                  style: tt.labelSmall?.copyWith(
                    color: subjectBadgeColor,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Icon(Icons.class_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(
                homework.className ?? 'Class',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // ─── Deadline + submission count ────────────────────────────
          Row(
            children: [
              Icon(
                _isOverdue ? Icons.event_busy_rounded : Icons.schedule_rounded,
                size: Spacings.smIcon,
                color: _isOverdue ? AppColors.error : cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                '${_formatDate(homework.deadline)} ${_formatTime(homework.deadline)}',
                style: tt.bodySmall?.copyWith(
                  color: _isOverdue ? AppColors.error : cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(Icons.people_outline_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                '${homework.submissionCount ?? 0} submitted',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),

          // ─── Teacher actions (publish) ──────────────────────────────
          if (isTeacher && homework.status == HomeworkStatus.draft) ...[
            const SizedBox(height: Spacings.md),
            const Divider(height: 1),
            const SizedBox(height: Spacings.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onPublish?.call(homework.id),
                  icon: const Icon(Icons.publish_rounded, size: Spacings.smIcon),
                  label: const Text('Publish'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                  ),
                ),
              ],
            ),
          ],

          // ─── Student view: submission status ────────────────────────
          if (!isTeacher) ...[
            const SizedBox(height: Spacings.sm),
            const Divider(height: 1),
            const SizedBox(height: Spacings.sm),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  'Not submitted', // Placeholder – read from student data
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}
