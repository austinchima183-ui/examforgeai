import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../providers/content_provider.dart';
import '../providers/content_review_provider.dart';
import '../providers/content_collection_provider.dart';
import '../providers/deployment_provider.dart';
import '../widgets/ccms_widgets.dart';
import 'content_editor_page.dart';

class ContentDetailPage extends ConsumerStatefulWidget {
  const ContentDetailPage({super.key, required this.contentId});

  final String contentId;

  @override
  ConsumerState<ContentDetailPage> createState() =>
      _ContentDetailPageState();
}

class _ContentDetailPageState extends ConsumerState<ContentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _usageIncremented = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(contentProvider.notifier)
          .loadContentById(widget.contentId);
      ref
          .read(contentProvider.notifier)
          .loadVersions(widget.contentId);
      ref
          .read(contentReviewProvider.notifier)
          .loadContentReviews(widget.contentId);
      // Increment usage count on view
      if (!_usageIncremented) {
        _usageIncremented = true;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentProvider);
    final reviewState = ref.watch(contentReviewProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final content =
        contentState.selectedContent;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Content Detail',
        actions: [
          AppIconButton(
            icon: Icons.edit_rounded,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContentEditorPage(
                      contentId: widget.contentId),
                ),
              );
            },
            tooltip: 'Edit',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'publish') {
                ref
                    .read(contentProvider.notifier)
                    .publishContent(widget.contentId);
              }
              if (v == 'archive') {
                ref
                    .read(contentProvider.notifier)
                    .archiveContent(widget.contentId);
              }
              if (v == 'collection') {
                _showAddToCollectionDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'publish', child: Text('Publish')),
              const PopupMenuItem(
                  value: 'archive', child: Text('Archive')),
              const PopupMenuItem(
                  value: 'collection', child: Text('Add to Collection')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Version History'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
      body: contentState.isLoading
          ? const Center(child: AppLoadingSpinner())
          : content == null
              ? AppErrorState.notFoundError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(content, cs, tt),
                    _buildVersionHistoryTab(contentState, cs, tt),
                    _buildReviewsTab(reviewState, cs, tt),
                  ],
                ),
      // Bottom action buttons
      bottomNavigationBar: content == null
          ? null
          : SafeArea(
              child: Padding(
                padding: Spacings.paddingScreen,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Edit',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContentEditorPage(
                                  contentId: widget.contentId),
                            ),
                          );
                        },
                        variant: AppButtonVariant.outlined,
                        icon: Icons.edit_outlined,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Publish',
                        onPressed: () => ref
                            .read(contentProvider.notifier)
                            .publishContent(widget.contentId),
                        icon: Icons.publish_rounded,
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Archive',
                        onPressed: () => ref
                            .read(contentProvider.notifier)
                            .archiveContent(widget.contentId),
                        variant: AppButtonVariant.tonal,
                        icon: Icons.archive_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailsTab(
      ContentItem content, ColorScheme cs, TextTheme tt) {
    return SingleChildScrollView(
      padding: Spacings.paddingScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badges
          Row(children: [
            ContentTypeBadge(contentType: content.contentType),
            const SizedBox(width: Spacings.sm),
            DifficultyIndicator(level: content.difficultyLevel ?? DifficultyLevel.intermediate),
            const Spacer(),
            if (content.isAiGenerated == true)
              Icon(Icons.auto_awesome_rounded,
                  color: cs.primary, size: Spacings.mdIcon),
            if (content.isPastQuestion == true)
              Padding(
                padding: const EdgeInsets.only(left: Spacings.xs),
                child: Icon(Icons.history_edu_rounded,
                    color: AppColors.warning, size: Spacings.mdIcon),
              ),
          ]),
          const SizedBox(height: Spacings.md),
          Text(content.title,
              style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold, color: cs.onSurface)),
          const SizedBox(height: Spacings.sm),
          Row(children: [
            Text('Status: ',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.sm, vertical: 2),
              decoration: BoxDecoration(
                  color:
                      _statusColor(content.status).withOpacity(0.15),
                  borderRadius: Spacings.borderRadiusSm),
              child: Text(content.status.label,
                  style: tt.labelSmall!.copyWith(
                      color: _statusColor(content.status),
                      fontWeight: AppTypography.wSemiBold)),
            ),
            const SizedBox(width: Spacings.md),
            if (content.averageQualityScore != null)
              QualityScoreIndicator(score: content.averageQualityScore!),
          ]),
          Spacings.sectionGap,

          // Body
          _DetailSection(
              title: 'Content', icon: Icons.article_rounded, content: content.body),
          Spacings.sectionGap,

          // Explanation
          if (content.stepByStepExplanation != null &&
              content.stepByStepExplanation!.isNotEmpty) ...[
            _DetailSection(
                title: 'Explanation',
                icon: Icons.lightbulb_outline_rounded,
                content: content.stepByStepExplanation!),
            Spacings.sectionGap,
          ],

          // Marking Scheme
          if (content.markingScheme != null) ...[
            _DetailSection(
                title: 'Marking Scheme',
                icon: Icons.grading_rounded,
                content: content.markingScheme!.toString()),
            Spacings.sectionGap,
          ],

          // Teacher Notes
          if (content.teacherNotes != null &&
              content.teacherNotes!.isNotEmpty) ...[
            _DetailSection(
                title: 'Teacher Notes',
                icon: Icons.sticky_note_2_outlined,
                content: content.teacherNotes!),
            Spacings.sectionGap,
          ],

          // Metadata
          _buildMetadataSection(content, cs, tt),
          Spacings.sectionGap,

          // Learning Objectives
          if (content.learningObjectiveIds != null &&
              content.learningObjectiveIds!.isNotEmpty) ...[
            Text('Learning Objectives',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.xs,
              children: content.learningObjectiveIds!
                  .map((id) => Chip(
                        label: Text(id),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            Spacings.sectionGap,
          ],

          // Tags
          if (content.tags != null && content.tags!.isNotEmpty) ...[
            Text('Tags',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.xs,
              children: content.tags!
                  .map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            Spacings.sectionGap,
          ],

          // Usage Statistics
          Text('Usage Statistics',
              style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
          const SizedBox(height: Spacings.sm),
          StatOverviewCard(
            title: 'Usage Count',
            value: '${content.usageCount}',
            icon: Icons.visibility_rounded,
            color: AppColors.info,
          ),
          Spacings.sectionGap,

          // Related Content Suggestions
          Text('Related Content',
              style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
          const SizedBox(height: Spacings.sm),
          AppEmptyState.noData(subtitle: 'No related content found'),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(
      ContentItem content, ColorScheme cs, TextTheme tt) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metadata',
              style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.primary)),
          const SizedBox(height: Spacings.sm),
          _metaRow('Subject ID', content.subjectId, cs, tt),
          _metaRow('Level ID', content.educationalLevelId, cs, tt),
          if (content.topicId != null)
            _metaRow('Topic ID', content.topicId!, cs, tt),
          _metaRow('Difficulty', content.difficultyLevel?.label ?? 'N/A', cs, tt),
          _metaRow("Bloom's Level", content.bloomLevel?.label ?? 'N/A', cs, tt),
          _metaRow('Source Type', content.sourceType ?? 'N/A', cs, tt),
          if (content.marksAllocated != null)
            _metaRow('Marks', '${content.marksAllocated}', cs, tt),
          if (content.timeAllocatedSeconds != null)
            _metaRow('Time', '${content.timeAllocatedSeconds} min', cs, tt),
          if (content.isPastQuestion == true) ...[
            _metaRow('Past Question', 'Yes', cs, tt),
          ],
          _metaRow('AI Generated',
              (content.isAiGenerated == true) ? 'Yes' : 'No', cs, tt),
        ],
      ),
    );
  }

  Widget _metaRow(
      String label, String value, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: AppTypography.wMedium)),
          ),
          Expanded(
            child: Text(value, style: tt.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionHistoryTab(
      ContentState contentState, ColorScheme cs, TextTheme tt) {
    if (contentState.versions.isEmpty) {
      return AppEmptyState.noData(subtitle: 'No version history');
    }
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: contentState.versions.length,
      itemBuilder: (context, index) {
        final v = contentState.versions[index];
        return Card(
          child: ListTile(
            leading: Icon(
              (v.versionNumber == contentState.selectedContent?.version) ? Icons.new_releases_rounded : Icons.history_rounded,
              color: (v.versionNumber == contentState.selectedContent?.version) ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text('v${v.versionNumber}'),
            subtitle: Text(
                'By ${v.createdBy ?? 'Unknown'} · ${_formatDate(v.createdAt)}'),
            trailing: (v.versionNumber == contentState.selectedContent?.version)
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.15),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text('Current',
                        style: tt.labelSmall!.copyWith(
                            color: cs.primary,
                            fontWeight: AppTypography.wSemiBold)),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(
      ContentReviewState reviewState, ColorScheme cs, TextTheme tt) {
    if (reviewState.reviews.isEmpty) {
      return AppEmptyState.noData(subtitle: 'No reviews yet');
    }
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: reviewState.reviews.length,
      itemBuilder: (context, index) {
        final r = reviewState.reviews[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(r.reviewerId,
                      style: tt.labelMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold)),
                  const Spacer(),
                  Text(_formatDate(r.reviewedAt),
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ]),
                if (r.qualityScore != null) ...[
                  const SizedBox(height: Spacings.sm),
                  QualityScoreIndicator(score: r.qualityScore!),
                ],
                const SizedBox(height: Spacings.xs),
                Text(r.comment ?? '', style: tt.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToCollectionDialog() {
    final collectionState = ref.read(contentCollectionProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Collection'),
        content: SizedBox(
          width: double.maxFinite,
          child: collectionState.collections.isEmpty
              ? Text('No collections available. Create one first.',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: collectionState.collections.length,
                  itemBuilder: (context, index) {
                    final collection = collectionState.collections[index];
                    return ListTile(
                      leading: const Icon(Icons.collections_bookmark_rounded),
                      title: Text(collection.name),
                      subtitle: Text('${collection.contentCount} items'),
                      onTap: () {
                        ref
                            .read(contentCollectionProvider.notifier)
                            .addCollectionItem(ContentCollectionItem(
                                id: '',
                                collectionId: collection.id,
                                contentItemId: widget.contentId,
                                sortOrder: 0,
                                addedAt: DateTime.now(),
                              ));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Added to ${collection.name}')),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.text,
          ),
        ],
      ),
    );
  }

  Color _statusColor(ContentStatus status) {
    return switch (status) {
      ContentStatus.draft => AppColors.warning,
      ContentStatus.review => AppColors.info,
      ContentStatus.published => AppColors.success,
      ContentStatus.archived => const Color(0xFF6B7280),
      ContentStatus.deprecated => AppColors.error,
    };
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: Spacings.xs),
          Text(title,
              style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.primary)),
        ]),
        const SizedBox(height: Spacings.sm),
        Container(
          width: double.infinity,
          padding: Spacings.paddingCard,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: Spacings.borderRadiusMd,
          ),
          child: Text(content, style: tt.bodyMedium),
        ),
      ],
    );
  }
}
