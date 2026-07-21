import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

export 'content_editor_page.dart';

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
          .loadContentWithDetails(widget.contentId);
      ref
          .read(contentProvider.notifier)
          .loadContentVersions(widget.contentId);
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
        contentState.contentWithDetails ?? contentState.selectedContent;

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
            DifficultyIndicator(level: content.difficultyLevel),
            const Spacer(),
            if (content.isAiGenerated)
              Icon(Icons.auto_awesome_rounded,
                  color: cs.primary, size: Spacings.mdIcon),
            if (content.isPastQuestion)
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
                      _statusColor(content.status).withValues(alpha: 0.15),
                  borderRadius: Spacings.borderRadiusSm),
              child: Text(content.status.label,
                  style: AppTypography.labelSmall.copyWith(
                      color: _statusColor(content.status),
                      fontWeight: AppTypography.wSemiBold)),
            ),
            const SizedBox(width: Spacings.md),
            if (content.qualityScore != null)
              QualityScoreIndicator(score: content.qualityScore!),
          ]),
          Spacings.sectionGap,

          // Body
          _DetailSection(
              title: 'Content', icon: Icons.article_rounded, content: content.body),
          Spacings.sectionGap,

          // Explanation
          if (content.explanation != null &&
              content.explanation!.isNotEmpty) ...[
            _DetailSection(
                title: 'Explanation',
                icon: Icons.lightbulb_outline_rounded,
                content: content.explanation!),
            Spacings.sectionGap,
          ],

          // Marking Scheme
          if (content.markingScheme != null &&
              content.markingScheme!.isNotEmpty) ...[
            _DetailSection(
                title: 'Marking Scheme',
                icon: Icons.grading_rounded,
                content: content.markingScheme!),
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
          if (content.learningObjectives != null &&
              content.learningObjectives!.isNotEmpty) ...[
            Text('Learning Objectives',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold, color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.xs,
              children: content.learningObjectives!
                  .map((obj) => LearningObjectiveChip(objective: obj))
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
          _metaRow('Difficulty', content.difficultyLevel.label, cs, tt),
          _metaRow("Bloom's Level", content.bloomLevel.label, cs, tt),
          _metaRow('Source Type', content.sourceType.label, cs, tt),
          if (content.markAllocation != null)
            _metaRow('Marks', '${content.markAllocation}', cs, tt),
          if (content.timeAllocationMinutes != null)
            _metaRow('Time', '${content.timeAllocationMinutes} min', cs, tt),
          if (content.isPastQuestion) ...[
            _metaRow('Past Question', 'Yes', cs, tt),
          ],
          _metaRow('AI Generated',
              content.isAiGenerated ? 'Yes' : 'No', cs, tt),
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
    if (contentState.contentVersions.isEmpty) {
      return AppEmptyState.noData(subtitle: 'No version history');
    }
    return ListView.builder(
      padding: Spacings.paddingScreen,
      itemCount: contentState.contentVersions.length,
      itemBuilder: (context, index) {
        final v = contentState.contentVersions[index];
        return Card(
          child: ListTile(
            leading: Icon(
              v.isCurrent ? Icons.new_releases_rounded : Icons.history_rounded,
              color: v.isCurrent ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text('v${v.versionNumber}'),
            subtitle: Text(
                'By ${v.changedBy} · ${_formatDate(v.changedAt)}'),
            trailing: v.isCurrent
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: Spacings.borderRadiusSm,
                    ),
                    child: Text('Current',
                        style: AppTypography.labelSmall.copyWith(
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
                  Text(_formatDate(r.createdAt),
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                ]),
                if (r.qualityScore != null) ...[
                  const SizedBox(height: Spacings.sm),
                  QualityScoreIndicator(score: r.qualityScore!),
                ],
                const SizedBox(height: Spacings.xs),
                Text(r.comments, style: tt.bodyMedium),
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
                  style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: collectionState.collections.length,
                  itemBuilder: (context, index) {
                    final collection = collectionState.collections[index];
                    return ListTile(
                      leading: const Icon(Icons.collections_bookmark_rounded),
                      title: Text(collection.name),
                      subtitle: Text('${collection.itemCount} items'),
                      onTap: () {
                        ref
                            .read(contentCollectionProvider.notifier)
                            .addCollectionItem(
                                collectionId: collection.id,
                                contentItemId: widget.contentId);
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
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: Spacings.borderRadiusMd,
          ),
          child: Text(content, style: tt.bodyMedium),
        ),
      ],
    );
  }
}
