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
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/school_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// SCHOOL LIST PAGE (Super Admin)
// ═══════════════════════════════════════════════════════════════════════

/// Super admin's school list page with search, filters, and responsive grid.
/// Shows all registered schools with key metrics and subscription status.
class SchoolListPage extends ConsumerStatefulWidget {
  const SchoolListPage({super.key});

  @override
  ConsumerState<SchoolListPage> createState() => _SchoolListPageState();
}

class _SchoolListPageState extends ConsumerState<SchoolListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  String _filterStatus = 'all'; // all, active, inactive

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load schools on init
    Future.microtask(() {
      ref.read(schoolListProvider.notifier).loadSchools();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(schoolListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SchoolEntity> _applyFilters(List<SchoolEntity> schools) {
    var filtered = schools;
    if (_filterStatus == 'active') {
      filtered = filtered.where((s) => s.isActive).toList();
    } else if (_filterStatus == 'inactive') {
      filtered = filtered.where((s) => !s.isActive).toList();
    }
    return filtered;
  }

  Color _subscriptionColor(String status) {
    switch (status) {
      case 'premium':
        return AppColors.success;
      case 'basic':
        return AppColors.info;
      case 'free':
      default:
        return AppColors.warning;
    }
  }

  String _subscriptionLabel(String status) {
    switch (status) {
      case 'premium':
        return 'Premium';
      case 'basic':
        return 'Basic';
      case 'free':
      default:
        return 'Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(schoolListProvider);
    final filteredSchools = _applyFilters(state.schools);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Schools',
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
                ref.read(schoolListProvider.notifier).loadSchools();
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search schools',
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter schools',
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
                    hint: 'Search schools by name or code...',
                    controller: _searchController,
                    onChanged: (query) {
                      if (query.isEmpty) {
                        ref.read(schoolListProvider.notifier).loadSchools();
                      } else {
                        ref.read(schoolListProvider.notifier).searchSchools(query);
                      }
                    },
                    onSubmitted: (query) {
                      ref.read(schoolListProvider.notifier).searchSchools(query);
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(schoolListProvider.notifier).refresh(),
        child: _buildBody(context, state, filteredSchools),
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go(RouteNames.schoolAdminDashboard),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add School'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SchoolListState state,
    List<SchoolEntity> schools,
  ) {
    if (state.isLoading && schools.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && schools.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(schoolListProvider.notifier).loadSchools(),
      );
    }

    if (schools.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4),
          AppEmptyState(
            icon: Icons.school_outlined,
            title: _isSearchMode ? 'No Matching Schools' : 'No Schools Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Register the first school to get started.',
            actionLabel: _isSearchMode ? null : 'Add School',
            onAction: _isSearchMode
                ? null
                : () => context.go(RouteNames.schoolAdminDashboard),
          ),
        ],
      );
    }

    return _buildSchoolGrid(context, schools, state);
  }

  Widget _buildSchoolGrid(
    BuildContext context,
    List<SchoolEntity> schools,
    SchoolListState state,
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
            controller: _scrollController,
            padding: const EdgeInsets.all(Spacings.md),
            itemCount: schools.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == schools.length) {
                return _buildLoadMoreIndicator(state);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: _SchoolCard(
                  school: schools[index],
                  subscriptionColor: _subscriptionColor,
                  subscriptionLabel: _subscriptionLabel,
                  onTap: () => _navigateToDetail(schools[index].id),
                  onEdit: () => context.go(RouteNames.schoolAdminDashboard),
                  onDelete: () => _showDeleteConfirmation(schools[index]),
                ),
              );
            },
          );
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(Spacings.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.8,
            crossAxisSpacing: Spacings.md,
            mainAxisSpacing: Spacings.md,
          ),
          itemCount: schools.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == schools.length) {
              return _buildLoadMoreIndicator(state);
            }
            return _SchoolCard(
              school: schools[index],
              subscriptionColor: _subscriptionColor,
              subscriptionLabel: _subscriptionLabel,
              onTap: () => _navigateToDetail(schools[index].id),
              onEdit: () => context.go(RouteNames.schoolAdminDashboard),
              onDelete: () => _showDeleteConfirmation(schools[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator(SchoolListState state) {
    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: state.isLoading
            ? const AppLoadingSpinner(size: AppLoadingSpinnerSize.small)
            : const SizedBox.shrink(),
      ),
    );
  }

  void _navigateToDetail(String schoolId) {
    // Navigate to school detail page
    context.go('${RouteNames.schoolAdminDashboard}?schoolId=$schoolId');
  }

  void _showDeleteConfirmation(SchoolEntity school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete School'),
        content: Text(
          'Are you sure you want to delete "${school.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(schoolListProvider.notifier).deleteSchool(school.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final cs = context.colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Spacings.lgRadius)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Schools',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              Wrap(
                spacing: Spacings.sm,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterStatus == 'all',
                    onSelected: () {
                      setState(() => _filterStatus = 'all');
                      setModalState(() => _filterStatus = 'all');
                    },
                  ),
                  _FilterChip(
                    label: 'Active',
                    selected: _filterStatus == 'active',
                    onSelected: () {
                      setState(() => _filterStatus = 'active');
                      setModalState(() => _filterStatus = 'active');
                    },
                  ),
                  _FilterChip(
                    label: 'Inactive',
                    selected: _filterStatus == 'inactive',
                    onSelected: () {
                      setState(() => _filterStatus = 'inactive');
                      setModalState(() => _filterStatus = 'inactive');
                    },
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply',
                  onPressed: () => Navigator.pop(ctx),
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
// SCHOOL CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({
    required this.school,
    required this.subscriptionColor,
    required this.subscriptionLabel,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final SchoolEntity school;
  final Color Function(String) subscriptionColor;
  final String Function(String) subscriptionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Logo, Name, Status ────────────────────────────
          Row(
            children: [
              // School logo / avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: school.isActive
                      ? cs.primary.withOpacity(isDark ? 0.20 : 0.12)
                      : cs.onSurface.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(Spacings.mdRadius),
                ),
                child: school.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(Spacings.mdRadius),
                        child: Image.network(
                          school.logoUrl!,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.school_rounded,
                            color: school.isActive ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.school_rounded,
                        color: school.isActive ? cs.primary : cs.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: Spacings.md),
              // School name and code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(Spacings.smRadius),
                          ),
                          child: Text(
                            school.code,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),
                        if (school.city != null) ...[
                          const SizedBox(width: Spacings.sm),
                          Icon(
                            Icons.location_on_outlined,
                            size: Spacings.smIcon,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            school.city!,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Subscription badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: subscriptionColor(school.subscriptionStatus)
                      .withOpacity(isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.fullRadius),
                ),
                child: Text(
                  subscriptionLabel(school.subscriptionStatus),
                  style: tt.labelSmall?.copyWith(
                    color: subscriptionColor(school.subscriptionStatus),
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          // ── Stats Row ──────────────────────────────────────────────
          Row(
            children: [
              _StatPill(
                icon: Icons.people_outline_rounded,
                label: 'Students',
                value: '${school.maxStudents}',
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.md),
              _StatPill(
                icon: Icons.person_outline_rounded,
                label: 'Teachers',
                value: '${school.maxTeachers}',
                color: AppColors.info,
              ),
              const SizedBox(width: Spacings.md),
              _StatPill(
                icon: Icons.account_tree_outlined,
                label: 'Branches',
                value: '${school.branches.length}',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          // ── Actions Row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: Spacings.smIcon),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                  ),
                ),
              if (onDelete != null) ...[
                const SizedBox(width: Spacings.sm),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: Spacings.smIcon),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm,
          vertical: Spacings.sm,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Spacings.smIcon, color: color),
            const SizedBox(width: Spacings.xs),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: tt.labelSmall?.copyWith(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: cs.primary.withOpacity(0.12),
      checkmarkColor: cs.primary,
      labelStyle: TextStyle(
        color: selected ? cs.primary : cs.onSurfaceVariant,
        fontWeight: selected ? AppTypography.wSemiBold : AppTypography.wRegular,
      ),
    );
  }
}
