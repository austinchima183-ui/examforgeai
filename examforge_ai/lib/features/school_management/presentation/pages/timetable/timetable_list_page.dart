import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../domain/entities/school_management_entities.dart';
import '../providers/timetable_provider.dart';
import '../providers/academic_session_provider.dart';
import 'timetable_builder_page.dart';
import 'timetable_view_page.dart';

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School admin's timetable list page with term filter, type filter,
/// and FAB to create a new timetable.
class TimetableListPage extends ConsumerStatefulWidget {
  const TimetableListPage({super.key});

  @override
  ConsumerState<TimetableListPage> createState() => _TimetableListPageState();
}

class _TimetableListPageState extends ConsumerState<TimetableListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  String? _termFilter;
  String? _typeFilter;

  static const _timetableTypes = [
    ('class', 'Class Timetable'),
    ('teacher', 'Teacher Timetable'),
    ('exam', 'Exam Timetable'),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(timetableListProvider.notifier).loadTimetables(
            schoolId: 'current-school',
            termId: _termFilter,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<TimetableEntity> _applyFilters(List<TimetableEntity> timetables) {
    var filtered = timetables;

    // Search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        final nameMatch = t.name.toLowerCase().contains(query);
        final classMatch = t.className?.toLowerCase().contains(query) ?? false;
        return nameMatch || classMatch;
      }).toList();
    }

    // Type filter
    if (_typeFilter != null) {
      filtered = filtered
          .where((t) => t.timetableType == _typeFilter)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(timetableListProvider);
    final filteredTimetables = _applyFilters(state.timetables);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Timetables',
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
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search timetables',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter timetables',
          ),
        ],
        bottom: _isSearchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  child: AppSearchBar(
                    hint: 'Search by name, class...',
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(timetableListProvider.notifier).loadTimetables(
              schoolId: 'current-school',
              termId: _termFilter,
            ),
        child: _buildBody(context, state, filteredTimetables),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToBuilder(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Timetable'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
    );
  }

  // ─── Body Builder ────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    TimetableListState state,
    List<TimetableEntity> timetables,
  ) {
    if (state.isLoading && timetables.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && timetables.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(timetableListProvider.notifier).loadTimetables(
              schoolId: 'current-school',
            ),
      );
    }

    if (timetables.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          AppEmptyState(
            icon: Icons.schedule_outlined,
            title: _isSearchMode
                ? 'No Matching Timetables'
                : 'No Timetables Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Create the first timetable to get started.',
            actionLabel: _isSearchMode ? null : 'Create Timetable',
            onAction:
                _isSearchMode ? null : () => _navigateToBuilder(context),
          ),
        ],
      );
    }

    return _buildTimetableList(context, timetables);
  }

  // ─── Timetable List ──────────────────────────────────────────────────

  Widget _buildTimetableList(
    BuildContext context,
    List<TimetableEntity> timetables,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: timetables.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _TimetableCard(
            timetable: timetables[index],
            onTap: () => _navigateToDetail(context, timetables[index]),
          ),
        );
      },
    );
  }

  // ─── Navigation ──────────────────────────────────────────────────────

  void _navigateToBuilder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TimetableBuilderPage(),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, TimetableEntity timetable) {
    if (timetable.isPublished) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TimetableViewPage(timetableId: timetable.id),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TimetableBuilderPage(timetableId: timetable.id),
        ),
      );
    }
  }

  // ─── Filter Bottom Sheet ─────────────────────────────────────────────

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                'Filter Timetables',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Term filter
              DropdownButtonFormField<String>(
                value: _termFilter,
                decoration: const InputDecoration(
                  labelText: 'Term',
                  prefixIcon: Icon(Icons.calendar_view_week_outlined),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Terms'),
                  ),
                  DropdownMenuItem(value: 'current-term', child: Text('Current Term')),
                ],
                onChanged: (value) {
                  setState(() => _termFilter = value);
                  setModalState(() => _termFilter = value);
                },
              ),
              const SizedBox(height: Spacings.lg),
              // Type filter
              DropdownButtonFormField<String>(
                value: _typeFilter,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ..._timetableTypes.map(
                    (type) => DropdownMenuItem(
                      value: type.$1,
                      child: Text(type.$2),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _typeFilter = value);
                  setModalState(() => _typeFilter = value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply',
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(timetableListProvider.notifier).loadTimetables(
                          schoolId: 'current-school',
                          termId: _termFilter,
                        );
                  },
                  variant: AppButtonVariant.elevated,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TIMETABLE CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _TimetableCard extends StatelessWidget {
  const _TimetableCard({
    required this.timetable,
    this.onTap,
  });

  final TimetableEntity timetable;
  final VoidCallback? onTap;

  Color _typeColor(String type) {
    switch (type) {
      case 'class':
        return AppColors.info;
      case 'teacher':
        return const Color(0xFF8B5CF6);
      case 'exam':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'class':
        return 'Class';
      case 'teacher':
        return 'Teacher';
      case 'exam':
        return 'Exam';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final typeColor = _typeColor(timetable.timetableType);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Type icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(
              timetable.timetableType == 'exam'
                  ? Icons.assignment_outlined
                  : Icons.schedule_rounded,
              color: typeColor,
            ),
          ),
          const SizedBox(width: Spacings.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timetable.name,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        _typeLabel(timetable.timetableType),
                        style: tt.labelSmall?.copyWith(
                          color: typeColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    // Class name
                    if (timetable.className != null) ...[
                      const SizedBox(width: Spacings.sm),
                      Icon(Icons.class_outlined,
                          size: Spacings.smIcon, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          timetable.className!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                // Term info
                Row(
                  children: [
                    Icon(Icons.calendar_view_week_outlined,
                        size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      'Term: ${timetable.termId}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: Spacings.md),
                    Icon(Icons.grid_view_outlined,
                        size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(
                      '${timetable.slots.length} slots',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Published status
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: (timetable.isPublished
                      ? AppColors.success
                      : cs.outline)
                  .withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.fullRadius),
            ),
            child: Text(
              timetable.isPublished ? 'Published' : 'Draft',
              style: tt.labelSmall?.copyWith(
                color:
                    timetable.isPublished ? AppColors.success : cs.outline,
                fontWeight: AppTypography.wSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
