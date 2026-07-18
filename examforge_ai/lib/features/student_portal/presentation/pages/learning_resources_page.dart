import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Learning resources library page.
///
/// Features:
/// - Search bar at top
/// - Filter chips: Resource type (Notes, Worksheets, Study Guides, etc.)
/// - Subject filter dropdown
/// - Resource cards with: Title, Type badge, Subject, Teacher name,
///   View/Download count, Download button
/// - Resource detail: Content display, Download, Related resources
class LearningResourcesPage extends ConsumerStatefulWidget {
  const LearningResourcesPage({super.key});

  @override
  ConsumerState<LearningResourcesPage> createState() =>
      _LearningResourcesPageState();
}

class _LearningResourcesPageState
    extends ConsumerState<LearningResourcesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(resourceProvider.notifier).loadResources();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resourceState = ref.watch(resourceProvider);

    if (resourceState.currentResource != null) {
      return _buildResourceDetail(context, resourceState);
    }

    return _buildResourceList(context, resourceState);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESOURCE LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildResourceList(BuildContext context, ResourceState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Resources')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacings.lg,
              Spacings.md,
              Spacings.lg,
              Spacings.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(resourceProvider.notifier).search(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(Spacings.xlRadius),
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
              ),
              onSubmitted: (query) {
                ref.read(resourceProvider.notifier).search(query);
              },
            ),
          ),

          // Filter chips - resource type
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.lg,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Spacings.sm),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: state.filterType == null,
                    onSelected: (_) {
                      ref
                          .read(resourceProvider.notifier)
                          .filterByType(null);
                    },
                  ),
                ),
                ...StudentResourceType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: Spacings.sm),
                    child: FilterChip(
                      label: Text(type.label),
                      selected: state.filterType == type,
                      onSelected: (selected) {
                        ref.read(resourceProvider.notifier).filterByType(
                              selected ? type : null,
                            );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.sm),

          // Resource list
          Expanded(
            child: state.isLoading && state.resources.isEmpty
                ? const Center(child: AppLoadingSpinner())
                : state.error != null && state.resources.isEmpty
                    ? AppErrorState(
                        icon: Icons.error_outline_rounded,
                        title: 'Failed to Load Resources',
                        message: state.error,
                        onRetry: () => ref
                            .read(resourceProvider.notifier)
                            .loadResources(),
                      )
                    : state.resources.isEmpty
                        ? AppEmptyState.noResults(
                            onAction: () {
                              _searchController.clear();
                              ref
                                  .read(resourceProvider.notifier)
                                  .search(null);
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.lg,
                              vertical: Spacings.sm,
                            ),
                            itemCount: state.resources.length,
                            itemBuilder: (context, index) {
                              final resource = state.resources[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Spacings.md,
                                ),
                                child: _ResourceCard(
                                  resource: resource,
                                  onTap: () {
                                    ref
                                        .read(resourceProvider.notifier)
                                        .openResource(resource.id);
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESOURCE DETAIL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildResourceDetail(BuildContext context, ResourceState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final resource = state.currentResource!;

    return Scaffold(
      appBar: AppBar(
        title: Text(resource.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(resourceProvider.notifier).clearError();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  Wrap(
                    spacing: Spacings.md,
                    runSpacing: Spacings.sm,
                    children: [
                      _ResourceInfoChip(
                        icon: Icons.category_outlined,
                        label: resource.resourceType.label,
                        color: AppColors.info,
                      ),
                      if (resource.subjectName != null)
                        _ResourceInfoChip(
                          icon: Icons.menu_book_outlined,
                          label: resource.subjectName!,
                          color: AppColors.success,
                        ),
                      if (resource.teacherName != null)
                        _ResourceInfoChip(
                          icon: Icons.person_outline,
                          label: resource.teacherName!,
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacings.md),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        '${resource.viewCount} views',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: Spacings.lg),
                      Icon(
                        Icons.download_outlined,
                        size: Spacings.smIcon,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        '${resource.downloadCount} downloads',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Spacings.sectionGap,

            // Description
            if (resource.description != null) ...[
              _buildSectionTitle(context, 'Description'),
              const SizedBox(height: Spacings.sm),
              AppCard(
                child: Text(
                  resource.description!,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
              Spacings.sectionGap,
            ],

            // Content
            if (resource.content != null) ...[
              _buildSectionTitle(context, 'Content'),
              const SizedBox(height: Spacings.sm),
              AppCard(
                child: SelectableText(
                  resource.content!,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
              Spacings.sectionGap,
            ],

            // Download button
            if (resource.isDownloadable && resource.fileUrl != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(resourceProvider.notifier).logAccess(
                          resource.id,
                          accessType: 'download',
                        );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(
                    'Download ${resource.fileFormat?.toUpperCase() ?? 'File'}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.resource,
    required this.onTap,
  });

  final LearningResourceEntity resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(
                    alpha: context.isDarkMode ? 0.20 : 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(
                  _resourceTypeIcon(resource.resourceType),
                  size: Spacings.mdIcon,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
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
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(
                                Spacings.fullRadius),
                          ),
                          child: Text(
                            resource.resourceType.label,
                            style: tt.labelSmall?.copyWith(
                              color: cs.onTertiaryContainer,
                              fontWeight: AppTypography.wMedium,
                            ),
                          ),
                        ),
                        if (resource.subjectName != null) ...[
                          const SizedBox(width: Spacings.sm),
                          Text(
                            resource.subjectName!,
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
              if (resource.isDownloadable)
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 20),
                  onPressed: () {
                    // Download
                  },
                ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (resource.teacherName != null) ...[
                Icon(
                  Icons.person_outline,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  resource.teacherName!,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacings.lg),
              ],
              Icon(
                Icons.visibility_outlined,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                '${resource.viewCount}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _resourceTypeIcon(StudentResourceType type) {
    return switch (type) {
      StudentResourceType.lessonNote => Icons.note_outlined,
      StudentResourceType.worksheet => Icons.assignment_outlined,
      StudentResourceType.studyGuide => Icons.auto_stories_outlined,
      StudentResourceType.slide => Icons.slideshow_outlined,
      StudentResourceType.handout => Icons.description_outlined,
      StudentResourceType.recommendedReading =>
        Icons.local_library_outlined,
      StudentResourceType.videoLink => Icons.play_circle_outline,
      StudentResourceType.pastQuestion => Icons.quiz_outlined,
    };
  }
}

class _ResourceInfoChip extends StatelessWidget {
  const _ResourceInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.fullRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Spacings.smIcon, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      ),
    );
  }
}
