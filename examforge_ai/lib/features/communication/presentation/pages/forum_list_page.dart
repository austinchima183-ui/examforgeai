import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/communication_entities.dart';
import '../providers/forum_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// FORUM LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Lists discussion forums with filter by type.
///
/// Features:
/// - Filter by type: All, Community, Subject, Class, Club, Department
/// - Each card: name, description, type, member count, post count, last activity
/// - FAB to create forum (teacher/admin)
/// - Search bar
/// - Pull-to-refresh
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class ForumListPage extends ConsumerStatefulWidget {
  const ForumListPage({super.key});

  @override
  ConsumerState<ForumListPage> createState() => _State();
}

class _State extends ConsumerState<ForumListPage> {
  // ─── State ──────────────────────────────────────────────────────────

  String _searchQuery = '';
  ForumType? _typeFilter;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  static const _typeChips = <_TypeChip>[
    _TypeChip(label: 'All', type: null),
    _TypeChip(label: 'Community', type: ForumType.schoolCommunity),
    _TypeChip(label: 'Subject', type: ForumType.subject),
    _TypeChip(label: 'Class', type: ForumType.classForum),
    _TypeChip(label: 'Club', type: ForumType.club),
    _TypeChip(label: 'Department', type: ForumType.department),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumProvider.notifier).loadForums(
        const GetForumsParams(page: 1, perPage: 50),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Discussion Forums',
        isSearchMode: _isSearching,
        searchController: _searchController,
        searchHint: 'Search forums…',
        onSearchToggle: () => setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchQuery = '';
            _searchController.clear();
          }
        }),
        onSearchChanged: (q) => setState(() => _searchQuery = q),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: navigate to create forum */},
        tooltip: 'Create Forum',
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(ForumState state) {
    if (state.isLoading && state.forums.isEmpty) {
      return _buildShimmerLoading();
    }

    if (state.error != null && state.forums.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(forumProvider.notifier).loadForums(
          const GetForumsParams(page: 1, perPage: 50),
        ),
      );
    }

    final filtered = _filterForums(state.forums);

    return Column(
      children: [
        // ─── Type Filter Chips ───────────────────────────────────
        _buildTypeChips(),

        // ─── Forums List ─────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState.noData(
                  title: 'No Forums',
                  subtitle: _searchQuery.isNotEmpty ? 'No forums match your search.' : 'No discussion forums have been created yet.',
                  actionLabel: 'Create Forum',
                  onAction: () {/* TODO */},
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(forumProvider.notifier).loadForums(
                    const GetForumsParams(page: 1, perPage: 50),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacings.xxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
                    itemBuilder: (_, i) => _buildForumCard(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TYPE CHIPS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTypeChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacings.lg, vertical: Spacings.xs),
        children: _typeChips.map((chip) {
          final isSelected = _typeFilter == chip.type;
          return Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: FilterChip(
              label: Text(chip.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _typeFilter = isSelected ? null : chip.type),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FORUM CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildForumCard(DiscussionForumEntity forum) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final typeColor = _forumTypeColor(forum.forumType, cs.brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: Spacings.borderRadiusMd),
        child: InkWell(
          onTap: () {/* TODO: navigate to forum detail */},
          borderRadius: Spacings.borderRadiusMd,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Row ────────────────────────────────────
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: typeColor.withOpacity(0.12),
                      child: Icon(_forumTypeIcon(forum.forumType), color: typeColor, size: Spacings.mdIcon),
                    ),
                    const SizedBox(width: Spacings.md),
                    // Name + Type badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            forum.name,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: Spacings.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: Spacings.borderRadiusSm,
                            ),
                            child: Text(
                              forum.forumType.label,
                              style: tt.labelSmall?.copyWith(color: typeColor, fontWeight: AppTypography.wMedium),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (forum.isPinned)
                      Icon(Icons.push_pin, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                  ],
                ),

                // ─── Description ───────────────────────────────────
                if (forum.description != null && forum.description!.isNotEmpty) ...[
                  const SizedBox(height: Spacings.md),
                  Text(
                    forum.description!,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // ─── Stats Row ─────────────────────────────────────
                const SizedBox(height: Spacings.md),
                Row(
                  children: [
                    Icon(Icons.people_outline, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.xs),
                    Text('${forum.memberCount} members', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: Spacings.lg),
                    Icon(Icons.article_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.xs),
                    Text('${forum.postCount} posts', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    const Spacer(),
                    if (forum.lastActivityAt != null)
                      Text(_formatTimeAgo(forum.lastActivityAt!), style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.lg),
          child: Column(
            children: List.generate(5, (_) => Padding(
              padding: const EdgeInsets.only(bottom: Spacings.lg),
              child: Row(
                children: [
                  AppLoadingShimmer.box(width: 40, height: 40, shape: BoxShape.circle),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLoadingShimmer.box(width: 180, height: 14, borderRadius: Spacings.borderRadiusSm),
                        const SizedBox(height: Spacings.sm),
                        AppLoadingShimmer.box(height: 12, borderRadius: Spacings.borderRadiusSm),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER
  // ═══════════════════════════════════════════════════════════════════════

  List<DiscussionForumEntity> _filterForums(List<DiscussionForumEntity> forums) {
    return forums.where((f) {
      if (_typeFilter != null && f.forumType != _typeFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!f.name.toLowerCase().contains(q) && !(f.description?.toLowerCase().contains(q) ?? false)) return false;
      }
      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _forumTypeColor(ForumType type, Brightness brightness) {
    switch (type) {
      case ForumType.schoolCommunity:
        return AppColors.infoOf(brightness);
      case ForumType.subject:
        return const Color(0xFF7C3AED);
      case ForumType.classForum:
        return AppColors.warningOf(brightness);
      case ForumType.club:
        return AppColors.successOf(brightness);
      case ForumType.department:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _forumTypeIcon(ForumType type) {
    switch (type) {
      case ForumType.schoolCommunity:
        return Icons.groups_outlined;
      case ForumType.subject:
        return Icons.menu_book_outlined;
      case ForumType.classForum:
        return Icons.class_outlined;
      case ForumType.club:
        return Icons.sports_esports_outlined;
      case ForumType.department:
        return Icons.business_outlined;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _TypeChip {
  const _TypeChip({required this.label, this.type});
  final String label;
  final ForumType? type;
}
