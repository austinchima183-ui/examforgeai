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
import '../providers/announcement_provider.dart';
import '../../../../features/school_management/domain/entities/school_management_entities.dart' hide AnnouncementEntity, AnnouncementPriority, AnnouncementType;


// ═══════════════════════════════════════════════════════════════════════
// ANNOUNCEMENT LIST PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Lists announcements with filter by type.
///
/// Features:
/// - Filter tabs: All, School-wide, Class, Emergency, Holiday, Exam
/// - Priority badges (color-coded: urgent=red, high=orange, normal=default, low=grey)
/// - Each card shows: title, excerpt, type badge, author, date, view count, pinned
/// - FAB to create announcement (admin/teacher only)
/// - Acknowledge button for users
/// - Pull-to-refresh
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern.
class AnnouncementListPage extends ConsumerStatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  ConsumerState<AnnouncementListPage> createState() => _State();
}

class _State extends ConsumerState<AnnouncementListPage> with SingleTickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────

  late final TabController _tabController;

  static const _tabs = [
    _AnnTab(label: 'All', type: null),
    _AnnTab(label: 'School-wide', type: AnnouncementType.schoolWide),
    _AnnTab(label: 'Class', type: AnnouncementType.classAnnouncement),
    _AnnTab(label: 'Emergency', type: AnnouncementType.emergency),
    _AnnTab(label: 'Holiday', type: AnnouncementType.holiday),
    _AnnTab(label: 'Exam', type: AnnouncementType.examination),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementProvider.notifier).loadAnnouncements(
        const GetAnnouncementsParams(page: 1, perPage: 50),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(announcementProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Announcements',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: () {/* TODO: navigate to create announcement */},
        tooltip: 'New Announcement',
        child: const Icon(Icons.campaign_outlined),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(AnnouncementState state) {
    if (state.isLoading && state.announcements.isEmpty) {
      return _buildShimmerLoading();
    }

    if (state.error != null && state.announcements.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(announcementProvider.notifier).loadAnnouncements(
          const GetAnnouncementsParams(page: 1, perPage: 50),
        ),
      );
    }

    final filtered = _filterAnnouncements(state.announcements);

    if (filtered.isEmpty) {
      return AppEmptyState.noData(
        title: 'No Announcements',
        subtitle: 'No announcements found for this category.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(announcementProvider.notifier).loadAnnouncements(
        const GetAnnouncementsParams(page: 1, perPage: 50),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: Spacings.xxl),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: Spacings.sm),
        itemBuilder: (_, i) => _buildAnnouncementCard(filtered[i]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FILTER
  // ═══════════════════════════════════════════════════════════════════════

  List<AnnouncementEntity> _filterAnnouncements(List<AnnouncementEntity> anns) {
    final tabType = _tabs[_tabController.index].type;
    if (tabType == null) return anns;
    return anns.where((a) => a.announcementType == tabType).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENT CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAnnouncementCard(AnnouncementEntity ann) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final priorityColor = _priorityColor(ann.priority, cs.brightness);
    final typeColor = _typeColor(ann.announcementType, cs.brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
          side: BorderSide(color: ann.priority == AnnouncementPriority.urgent ? priorityColor.withOpacity(0.5) : cs.outlineVariant.withOpacity(0.3)),
        ),
        child: InkWell(
          onTap: () {/* TODO: navigate to detail */},
          borderRadius: Spacings.borderRadiusMd,
          child: Padding(
            padding: Spacings.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Row ────────────────────────────────────
                Row(
                  children: [
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Text(
                        ann.priority.label,
                        style: tt.labelSmall?.copyWith(
                          color: priorityColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacings.sm, vertical: Spacings.xs),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                      child: Text(
                        ann.announcementType.label,
                        style: tt.labelSmall?.copyWith(color: typeColor, fontWeight: AppTypography.wMedium),
                      ),
                    ),
                    const Spacer(),
                    if (ann.isPinned)
                      Icon(Icons.push_pin, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    if (ann.isAiGenerated)
                      Padding(
                        padding: const EdgeInsets.only(left: Spacings.xs),
                        child: Icon(Icons.auto_awesome, size: Spacings.smIcon, color: cs.primary),
                      ),
                  ],
                ),
                const SizedBox(height: Spacings.md),

                // ─── Title ─────────────────────────────────────────
                Text(
                  ann.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),

                // ─── Excerpt ───────────────────────────────────────
                Text(
                  ann.body,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.md),

                // ─── Footer Row ────────────────────────────────────
                Row(
                  children: [
                    Text(
                      '${ann.authorName} · ${_formatDate(ann.createdAt)}',
                      style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Icon(Icons.visibility_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.xs),
                    Text('${ann.viewCount}', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: Spacings.md),
                    // Acknowledge button
                    TextButton(
                      onPressed: () => ref.read(announcementProvider.notifier).acknowledgeAnnouncement(ann.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        ann.acknowledgedBy.isNotEmpty ? '✓ Acknowledged' : 'Acknowledge',
                        style: tt.labelSmall?.copyWith(
                          color: ann.acknowledgedBy.isNotEmpty ? AppColors.successOf(cs.brightness) : cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppLoadingShimmer.box(width: 120, height: 20, borderRadius: Spacings.borderRadiusSm),
                  const SizedBox(height: Spacings.sm),
                  AppLoadingShimmer.box(width: double.infinity, height: 16, borderRadius: Spacings.borderRadiusSm),
                  const SizedBox(height: Spacings.xs),
                  AppLoadingShimmer.box(width: double.infinity, height: 14, borderRadius: Spacings.borderRadiusSm),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Color _priorityColor(AnnouncementPriority priority, Brightness brightness) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return AppColors.errorOf(brightness);
      case AnnouncementPriority.high:
        return AppColors.warningOf(brightness);
      case AnnouncementPriority.normal:
        return AppColors.infoOf(brightness);
      case AnnouncementPriority.low:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _typeColor(AnnouncementType type, Brightness brightness) {
    switch (type) {
      case AnnouncementType.emergency:
        return AppColors.errorOf(brightness);
      case AnnouncementType.holiday:
        return AppColors.successOf(brightness);
      case AnnouncementType.examination:
        return const Color(0xFF7C3AED);
      case AnnouncementType.schoolWide:
        return AppColors.infoOf(brightness);
      case AnnouncementType.classAnnouncement:
        return AppColors.warningOf(brightness);
      default:
        return AppColors.infoOf(brightness);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _AnnTab {
  const _AnnTab({required this.label, this.type});
  final String label;
  final AnnouncementType? type;
}
