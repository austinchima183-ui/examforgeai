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
import '../../domain/entities/school_management_entities.dart';
import '../../providers/parent_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// PARENT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// School admin's parent list page with search, pull-to-refresh,
/// pagination, and responsive layout.
class ParentListPage extends ConsumerStatefulWidget {
  const ParentListPage({super.key});

  @override
  ConsumerState<ParentListPage> createState() => _ParentListPageState();
}

class _ParentListPageState extends ConsumerState<ParentListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(parentListProvider.notifier).loadParents('current-school');
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(parentListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(parentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Parents',
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
                ref.read(parentListProvider.notifier).loadParents('current-school');
              }
            },
            tooltip: _isSearchMode ? 'Close search' : 'Search parents',
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
                    hint: 'Search by name or phone...',
                    controller: _searchController,
                    onChanged: (query) {
                      if (query.isEmpty) {
                        ref.read(parentListProvider.notifier).loadParents('current-school');
                      } else {
                        ref.read(parentListProvider.notifier).searchParents(query);
                      }
                    },
                    onSubmitted: (query) {
                      ref.read(parentListProvider.notifier).searchParents(query);
                    },
                  ),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(parentListProvider.notifier).refresh(),
        child: _buildBody(context, state, state.parents),
      ),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Navigate to add parent form
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Parent'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ParentListState state,
    List<ParentProfileEntity> parents,
  ) {
    if (state.isLoading && parents.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && parents.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(parentListProvider.notifier).loadParents('current-school'),
      );
    }

    if (parents.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.4),
          AppEmptyState(
            icon: Icons.family_restroom_outlined,
            title: _isSearchMode ? 'No Matching Parents' : 'No Parents Found',
            subtitle: _isSearchMode
                ? 'Try adjusting your search.'
                : 'Add the first parent to get started.',
            actionLabel: _isSearchMode ? null : 'Add Parent',
            onAction: _isSearchMode
                ? null
                : () {
                    // Navigate to add parent form
                  },
          ),
        ],
      );
    }

    return _buildParentList(context, parents, state);
  }

  Widget _buildParentList(
    BuildContext context,
    List<ParentProfileEntity> parents,
    ParentListState state,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: parents.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == parents.length) {
          return Padding(
            padding: const EdgeInsets.all(Spacings.lg),
            child: Center(
              child: state.isLoading
                  ? const AppLoadingSpinner(size: AppLoadingSpinnerSize.small)
                  : const SizedBox.shrink(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _ParentCard(
            parent: parents[index],
            onTap: () {
              // Navigate to parent detail
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARENT CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ParentCard extends StatelessWidget {
  const _ParentCard({
    required this.parent,
    this.onTap,
  });

  final ParentProfileEntity parent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final hasPrimaryContact = parent.children.any((c) => c.isPrimaryContact);
    final childrenCount = parent.children.length;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: parent.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    child: Image.network(
                      parent.avatarUrl!,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.info,
                      ),
                    ),
                  )
                : Icon(
                    Icons.family_restroom_rounded,
                    color: AppColors.info,
                  ),
          ),
          const SizedBox(width: Spacings.md),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.fullName ?? 'Unknown Parent',
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
                    if (parent.occupation != null) ...[
                      Icon(
                        Icons.work_outline_rounded,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          parent.occupation!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                    ],
                    Icon(
                      Icons.child_care_outlined,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$childrenCount ${childrenCount == 1 ? 'child' : 'children'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Primary contact badge
          if (hasPrimaryContact)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.sm,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
              child: Text(
                'PRIMARY',
                style: tt.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: AppTypography.wBold,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
