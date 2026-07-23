import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/child_assignments_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD ASSIGNMENTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Assignment viewer page for a specific child in the Parent Portal.
///
/// Displays a tabbed interface with assignment listings:
/// - Tab bar: All, Pending, Submitted, Graded, Missing
/// - Subject filter chips
/// - Expandable assignment cards with status badges
/// - Empty state per tab
/// - Pull-to-refresh support
///
/// Receives [studentId] as a route parameter and loads assignments
/// using [childAssignmentsProvider].
class ChildAssignmentsPage extends ConsumerStatefulWidget {
  const ChildAssignmentsPage({
    super.key,
    required this.studentId,
  });

  /// Unique identifier of the student whose assignments are displayed.
  final String studentId;

  @override
  ConsumerState<ChildAssignmentsPage> createState() => _State();
}

class _State extends ConsumerState<ChildAssignmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// The currently selected subject filter, or `null` for all subjects.
  String? _selectedSubject;

  /// Expanded assignment IDs for the expand/collapse feature.
  final Set<String> _expandedIds = {};

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(childAssignmentsProvider.notifier)
          .loadAssignments(widget.studentId);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ─── Tab Change Handler ─────────────────────────────────────────────

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final status = _tabStatus(_tabController.index);
      ref
          .read(childAssignmentsProvider.notifier)
          .loadAssignments(widget.studentId, status: status);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(childAssignmentsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Assignments',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Submitted'),
            Tab(text: 'Graded'),
            Tab(text: 'Missing'),
          ],
        ),
      ),
      body: _buildBody(context, assignmentsState),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ChildAssignmentsState state) {
    // Error state with no data
    if (state.error != null && state.assignments.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref
            .read(childAssignmentsProvider.notifier)
            .loadAssignments(widget.studentId),
      );
    }

    final assignments = _filterAssignments(state.assignments);

    return Column(
      children: [
        // ─── Subject Filter Chips ──────────────────────────────────
        _buildSubjectFilterChips(context, state.assignments),

        // ─── Assignment List ───────────────────────────────────────
        Expanded(
          child: state.isLoading && assignments.isEmpty
              ? _buildShimmerLoading(context)
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(childAssignmentsProvider.notifier)
                      .refreshAssignments(widget.studentId),
                  child: assignments.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                            bottom: Spacings.xxl,
                          ),
                          itemCount: assignments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Spacings.sm),
                          itemBuilder: (_, index) => _buildAssignmentCard(
                            context,
                            assignments[index],
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SUBJECT FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSubjectFilterChips(
    BuildContext context,
    List<ChildAssignmentEntity> assignments,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Extract unique subjects
    final subjects = assignments
        .map((a) => a.subjectName)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    if (subjects.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.xs,
        ),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedSubject == null,
              onSelected: (_) {
                setState(() => _selectedSubject = null);
              },
            ),
          ),
          // Subject chips
          ...subjects.map((subject) {
            return Padding(
              padding: const EdgeInsets.only(right: Spacings.sm),
              child: FilterChip(
                label: Text(subject),
                selected: _selectedSubject == subject,
                onSelected: (_) {
                  setState(() {
                    _selectedSubject =
                        _selectedSubject == subject ? null : subject;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: Spacings.md),
                child: AppLoadingShimmer.box(
                  height: 80,
                  borderRadius: Spacings.borderRadiusMd,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    final tabIndex = _tabController.index;
    final tabName = ['All', 'Pending', 'Submitted', 'Graded', 'Missing'][tabIndex];

    return AppEmptyState.noData(
      title: 'No $tabName Assignments',
      subtitle: 'There are no ${tabName.toLowerCase()} assignments to display.',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSIGNMENT CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAssignmentCard(
    BuildContext context,
    ChildAssignmentEntity assignment,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isExpanded = _expandedIds.contains(assignment.id);
    final statusColor = _statusColor(assignment.status, cs.brightness);
    final statusBg = _statusBackgroundColor(assignment.status, cs.brightness);
    final isOverdue = assignment.dueDate != null &&
        assignment.dueDate!.isBefore(DateTime.now()) &&
        assignment.status.toLowerCase() == 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: isOverdue
            ? AppColors.errorLight.withValues(alpha: 0.3)
            : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
          side: isOverdue
              ? BorderSide(
                  color: AppColors.errorOf(cs.brightness).withValues(alpha: 0.3),
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedIds.remove(assignment.id);
              } else {
                _expandedIds.add(assignment.id);
              }
            });
          },
          borderRadius: Spacings.borderRadiusMd,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Text(
                        _statusLabel(assignment.status),
                        style: tt.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Subject badge + due date
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    if (assignment.subjectName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Text(
                          assignment.subjectName!,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                    ],
                    if (assignment.dueDate != null) ...[
                      Icon(
                        Icons.schedule_outlined,
                        size: Spacings.smIcon,
                        color: isOverdue
                            ? AppColors.errorOf(cs.brightness)
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'Due: ${_formatDate(assignment.dueDate!)}',
                        style: tt.bodySmall?.copyWith(
                          color: isOverdue
                              ? AppColors.errorOf(cs.brightness)
                              : cs.onSurfaceVariant,
                          fontWeight: isOverdue
                              ? AppTypography.wSemiBold
                              : AppTypography.wRegular,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: Spacings.xs),
                        Text(
                          '(Overdue)',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.errorOf(cs.brightness),
                            fontWeight: AppTypography.wBold,
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    // Score (if graded)
                    if (assignment.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successOf(cs.brightness)
                              .withValues(alpha: 0.12),
                          borderRadius: Spacings.borderRadiusSm,
                        ),
                        child: Text(
                          '${assignment.score!.toStringAsFixed(1)}%',
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.successOf(cs.brightness),
                            fontWeight: AppTypography.wBold,
                          ),
                        ),
                      ),
                    // Expand icon
                    Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: Spacings.mdIcon,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),

                // Expanded details
                if (isExpanded) ...[
                  const SizedBox(height: Spacings.md),
                  const Divider(height: 1),
                  const SizedBox(height: Spacings.md),
                  // Description
                  if (assignment.description != null &&
                      assignment.description!.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      assignment.description!,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.md),
                  ],
                  // Submission info
                  if (assignment.submittedAt != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: Spacings.smIcon,
                          color: AppColors.successOf(cs.brightness),
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          'Submitted: ${_formatDate(assignment.submittedAt!)}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.sm),
                  ],
                  // Score detail (if graded)
                  if (assignment.score != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.grade_outlined,
                          size: Spacings.smIcon,
                          color: AppColors.successOf(cs.brightness),
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          'Score: ${assignment.score!.toStringAsFixed(1)}%',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.sm),
                  ],
                  // Feedback placeholder
                  if (assignment.status.toLowerCase() == 'graded')
                    Row(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: Spacings.smIcon,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacings.xs),
                        Text(
                          'Tap to view teacher feedback',
                          style: tt.bodySmall?.copyWith(
                            color: cs.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTERING
  // ═══════════════════════════════════════════════════════════════════════

  /// Filters assignments by subject if a subject filter is active.
  List<ChildAssignmentEntity> _filterAssignments(
    List<ChildAssignmentEntity> assignments,
  ) {
    if (_selectedSubject == null) return assignments;
    return assignments
        .where((a) => a.subjectName == _selectedSubject)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a tab index to the corresponding status filter string.
  String? _tabStatus(int index) {
    switch (index) {
      case 0:
        return null; // All
      case 1:
        return 'pending';
      case 2:
        return 'submitted';
      case 3:
        return 'graded';
      case 4:
        return 'missing';
      default:
        return null;
    }
  }

  /// Returns the display label for a given status string.
  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'submitted':
        return 'Submitted';
      case 'graded':
        return 'Graded';
      case 'missing':
        return 'Missing';
      default:
        return status;
    }
  }

  /// Returns the colour for a given assignment status.
  Color _statusColor(String status, Brightness brightness) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningOf(brightness);
      case 'submitted':
        return AppColors.infoOf(brightness);
      case 'graded':
        return AppColors.successOf(brightness);
      case 'missing':
        return AppColors.errorOf(brightness);
      default:
        return AppColors.infoOf(brightness);
    }
  }

  /// Returns the background colour for a given assignment status.
  Color _statusBackgroundColor(String status, Brightness brightness) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningLight;
      case 'submitted':
        return AppColors.infoLight;
      case 'graded':
        return AppColors.successLight;
      case 'missing':
        return AppColors.errorLight;
      default:
        return AppColors.infoLight;
    }
  }

  /// Formats a [DateTime] as a short date string.
  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}
