import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class ContentLibraryPage extends ConsumerStatefulWidget {
  const ContentLibraryPage({super.key});

  @override
  ConsumerState<ContentLibraryPage> createState() =>
      _ContentLibraryPageState();
}

class _ContentLibraryPageState extends ConsumerState<ContentLibraryPage> {
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _isGridView = false;
  bool _filterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentProvider.notifier).loadContentItems();
      ref.read(subjectProvider.notifier).loadSubjects();
      ref.read(educationalLevelProvider.notifier).loadEducationalLevels();
      ref.read(topicProvider.notifier).loadTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentProvider);
    final subjectState = ref.watch(subjectProvider);
    final levelState = ref.watch(educationalLevelProvider);
    final topicState = ref.watch(topicProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    var items = contentState.contentItems.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    items.sort((a, b) {
      switch (_sortBy) {
        case 'quality':
          return (b.qualityScore ?? 0).compareTo(a.qualityScore ?? 0);
        case 'usage':
          return b.usageCount.compareTo(a.usageCount);
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'Content Library',
        isSearchMode: _searchQuery.isNotEmpty,
        searchHint: 'Search content…',
        onSearchToggle: () => setState(() => _searchQuery = ''),
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        actions: [
          AppIconButton(
            icon: _isGridView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(
                  value: 'quality', child: Text('Sort by Quality')),
              const PopupMenuItem(
                  value: 'usage', child: Text('Sort by Usage')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter panel (collapsible)
          FilterPanel(
            subjects: subjectState.subjects,
            levels: levelState.levels,
            topics: topicState.topics,
            selectedSubjectId: contentState.filters.subjectId,
            selectedLevelId: contentState.filters.levelId,
            selectedTopicId: contentState.filters.topicId,
            selectedContentType: contentState.filters.contentType,
            selectedDifficulty: contentState.filters.difficulty,
            selectedStatus: contentState.filters.status,
            onSubjectChanged: (v) => _applyFilters(subjectId: v),
            onLevelChanged: (v) => _applyFilters(levelId: v),
            onTopicChanged: (v) => _applyFilters(topicId: v),
            onContentTypeChanged: (v) => _applyFilters(contentType: v),
            onDifficultyChanged: (v) => _applyFilters(difficulty: v),
            onStatusChanged: (v) => _applyFilters(status: v),
            onClearFilters: () {
              ref.read(contentProvider.notifier).clearFilters();
              ref.read(contentProvider.notifier).loadContentItems();
            },
          ),
          // Content list or grid
          Expanded(
            child: contentState.isLoading &&
                    contentState.contentItems.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : contentState.error != null
                    ? AppErrorState(
                        message: contentState.error,
                        onRetry: () => ref
                            .read(contentProvider.notifier)
                            .loadContentItems(),
                      )
                    : items.isEmpty
                        ? AppEmptyState.noResults(
                            subtitle: 'No content matches your filters',
                            onAction: () {
                              ref
                                  .read(contentProvider.notifier)
                                  .clearFilters();
                              ref
                                  .read(contentProvider.notifier)
                                  .loadContentItems();
                            },
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(contentProvider.notifier)
                                .loadContentItems(),
                            child: _isGridView
                                ? _buildGridView(items)
                                : _buildListView(items),
                          ),
          ),
          // Pagination
          if (contentState.contentItems.isNotEmpty)
            Padding(
              padding: Spacings.paddingScreen,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton(
                    label: 'Load More',
                    onPressed: () => ref
                        .read(contentProvider.notifier)
                        .loadNextPage(),
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.small,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: AppFloatingActionButton(
        icon: Icons.add_rounded,
        label: 'Create Content',
        extended: context.isDesktop,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContentEditorPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<ContentItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      itemCount: items.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: Spacings.sm),
        child: ContentItemCard(
          content: items[index],
          onTap: () {},
          onEdit: () {},
          onPublish: () => ref
              .read(contentProvider.notifier)
              .publishContent(items[index].id),
          onArchive: () => ref
              .read(contentProvider.notifier)
              .archiveContent(items[index].id),
          onAddToCollection: () {},
        ),
      ),
    );
  }

  Widget _buildGridView(List<ContentItem> items) {
    return GridView.builder(
      padding: Spacings.paddingScreen,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isDesktop ? 4 : (context.isTablet ? 3 : 2),
        childAspectRatio: 0.85,
        crossAxisSpacing: Spacings.md,
        mainAxisSpacing: Spacings.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final cs = context.colorScheme;
        final tt = context.textTheme;
        return AppCard(
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ContentTypeBadge(contentType: item.contentType),
                  const Spacer(),
                  DifficultyIndicator(level: item.difficultyLevel),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                item.title,
                style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacings.xs),
              Text(
                item.status.label,
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.qualityScore != null)
                    QualityScoreIndicator(score: item.qualityScore!),
                  Text(
                    '${item.usageCount} views',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters({
    String? subjectId,
    String? levelId,
    String? topicId,
    ContentType? contentType,
    DifficultyLevel? difficulty,
    ContentStatus? status,
  }) {
    final current = ref.read(contentProvider).filters;
    ref.read(contentProvider.notifier).setFilters(ContentFilterState(
      subjectId: subjectId ?? current.subjectId,
      levelId: levelId ?? current.levelId,
      topicId: topicId ?? current.topicId,
      contentType: contentType ?? current.contentType,
      difficulty: difficulty ?? current.difficulty,
      status: status ?? current.status,
    ));
    ref.read(contentProvider.notifier).loadContentItems();
  }
}

// Re-export for navigation from FAB
export 'content_editor_page.dart';
