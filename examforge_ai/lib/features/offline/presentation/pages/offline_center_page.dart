import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/providers/auth_state_provider.dart';
import '../../domain/entities/offline_entities.dart';
import '../providers/offline_provider.dart';
import '../widgets/offline_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// OFFLINE CENTER PAGE
// ═══════════════════════════════════════════════════════════════════════

/// The main offline management page with tabbed navigation.
///
/// Provides a central hub for managing offline content including:
/// - **Overview**: Connectivity status, sync health, storage usage
/// - **Resources**: Offline-available resources by type
/// - **Downloads**: Active, completed, and failed downloads
/// - **Drafts**: Saved draft work with edit/delete actions
/// - **Sync**: Pending/failed sync items with retry controls
class OfflineCenterPage extends ConsumerStatefulWidget {
  const OfflineCenterPage({super.key});

  @override
  ConsumerState<OfflineCenterPage> createState() => _State();
}

class _State extends ConsumerState<OfflineCenterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
    Tab(icon: Icon(Icons.folder_outlined), text: 'Resources'),
    Tab(icon: Icon(Icons.download_outlined), text: 'Downloads'),
    Tab(icon: Icon(Icons.edit_note_outlined), text: 'Drafts'),
    Tab(icon: Icon(Icons.sync_outlined), text: 'Sync'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Loads all offline data in parallel.
  void _loadData() {
    final userId = ref.read(userIdProvider);
    if (userId == null) return;

    ref.read(offlineProvider.notifier).loadSyncStatus(userId);
    ref.read(offlineProvider.notifier).loadOfflineResources(userId);
    ref.read(offlineProvider.notifier).loadDrafts(userId);
    ref.read(offlineProvider.notifier).loadConnectivityInfo();
    ref.read(offlineProvider.notifier).loadDownloads(userId);
  }

  @override
  Widget build(BuildContext context) {
    final offlineState = ref.watch(offlineProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Offline Center',
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: context.isMobile,
          labelStyle: context.textTheme.labelLarge,
          unselectedLabelStyle: context.textTheme.labelMedium,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(state: offlineState, onRefresh: _loadData),
          _ResourcesTab(state: offlineState, onRefresh: _loadData),
          _DownloadsTab(state: offlineState, onRefresh: _loadData),
          _DraftsTab(state: offlineState, onRefresh: _loadData),
          _SyncTab(state: offlineState, onRefresh: _loadData),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// OVERVIEW TAB
// ═══════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state, required this.onRefresh});

  final OfflineState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Connectivity Status ──────────────────────────────────
            _buildSectionHeader(context, 'Connection Status'),
            const SizedBox(height: Spacings.sm),
            _buildConnectivityCard(context),
            const SizedBox(height: Spacings.lg),

            // ─── Sync Status ──────────────────────────────────────────
            _buildSectionHeader(context, 'Sync Status'),
            const SizedBox(height: Spacings.sm),
            _buildSyncStatusCard(context),
            const SizedBox(height: Spacings.lg),

            // ─── Storage Usage ────────────────────────────────────────
            _buildSectionHeader(context, 'Storage Usage'),
            const SizedBox(height: Spacings.sm),
            StorageUsageBar(
              usedBytes: state.totalOfflineSizeBytes,
              totalBytes: 500 * 1024 * 1024, // 500 MB limit placeholder
              label: '${_formatBytes(state.totalOfflineSizeBytes)} of 500 MB',
            ),
            const SizedBox(height: Spacings.lg),

            // ─── Quick Actions ────────────────────────────────────────
            _buildSectionHeader(context, 'Quick Actions'),
            const SizedBox(height: Spacings.sm),
            _buildQuickActions(context),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final tt = context.textTheme;
    return Text(
      title,
      style: tt.titleMedium?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildConnectivityCard(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final info = state.connectivityInfo;

    final qualityColor = _qualityColor(info?.connectionQuality);
    final qualityLabel = info?.connectionQuality.label ?? 'Unknown';
    final isOnline = info?.isOnline ?? false;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            ConnectionQualityIndicator(
              quality: info?.connectionQuality,
              size: 48,
            ),
            const SizedBox(width: Spacings.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '$qualityLabel · ${info?.connectionType.label ?? "—"}'
                    '${info?.latencyMs != null ? " · ${info!.latencyMs}ms" : ""}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: qualityColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final sync = state.syncStatus;

    return Card(
      elevation: Spacings.elevationSm,
      shadowColor: cs.shadow.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusLg,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SyncStatusChip(
                  syncStatus: sync?.syncHealth == SyncHealth.good
                      ? SyncChipStatus.synced
                      : sync?.hasIssues == true
                          ? SyncChipStatus.conflict
                          : SyncChipStatus.pending,
                ),
                const SizedBox(width: Spacings.sm),
                Text(
                  sync?.isSyncing == true ? 'Syncing…' : 'Up to date',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            Row(
              children: [
                _buildSyncCount(context, 'Pending', sync?.pendingCount ?? 0, AppColors.warning),
                const SizedBox(width: Spacings.lg),
                _buildSyncCount(context, 'Failed', sync?.failedCount ?? 0, AppColors.error),
                const SizedBox(width: Spacings.lg),
                _buildSyncCount(context, 'Done', sync?.completedCount ?? 0, AppColors.success),
              ],
            ),
            if (sync?.lastSyncAt != null) ...[
              const SizedBox(height: Spacings.md),
              Text(
                'Last synced: ${_formatDateTime(sync!.lastSyncAt!)}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCount(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    final tt = context.textTheme;
    return Column(
      children: [
        Text(
          '$count',
          style: tt.headlineSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: color,
          ),
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              final userId = context.widget.toString();
              // Trigger sync via provider — handled by parent
            },
            icon: const Icon(Icons.sync, size: Spacings.mdIcon),
            label: const Text('Sync Now'),
            style: FilledButton.styleFrom(
              padding: Spacings.paddingButton,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Clear cache action
            },
            icon: const Icon(Icons.cleaning_services_outlined, size: Spacings.mdIcon),
            label: const Text('Clear Cache'),
            style: OutlinedButton.styleFrom(
              padding: Spacings.paddingButton,
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusMd,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _qualityColor(ConnectionQuality? quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return AppColors.success;
      case ConnectionQuality.good:
        return AppColors.info;
      case ConnectionQuality.limited:
        return AppColors.warning;
      case ConnectionQuality.offline:
        return AppColors.error;
      case null:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RESOURCES TAB
// ═══════════════════════════════════════════════════════════════════════

class _ResourcesTab extends ConsumerWidget {
  const _ResourcesTab({required this.state, required this.onRefresh});

  final OfflineState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final resources = state.offlineResources;

    if (state.isLoading && resources.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (resources.isEmpty) {
      return AppEmptyState.generic(
        icon: Icons.folder_off_outlined,
        message: 'No offline resources',
        subtitle: 'Download resources to access them without internet',
        onAction: onRefresh,
        actionLabel: 'Refresh',
      );
    }

    // Group resources by type
    final grouped = <String, List<OfflineResource>>{};
    for (final r in resources) {
      grouped.putIfAbsent(r.resourceType, () => []).add(r);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final type = grouped.keys.elementAt(index);
          final items = grouped[type]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Padding(
                padding: const EdgeInsets.only(
                  bottom: Spacings.sm,
                  top: index == 0 ? 0 : Spacings.lg,
                ),
                child: Text(
                  _resourceTypeLabel(type),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.primary,
                  ),
                ),
              ),
              // Resource cards
              ...items.map((resource) => _buildResourceCard(context, ref, resource)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    WidgetRef ref,
    OfflineResource resource,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacings.sm),
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: OfflineIndicator(isAvailable: resource.isAvailable),
        title: Text(
          resource.title,
          style: tt.bodyMedium?.copyWith(
            fontWeight: AppTypography.wMedium,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${resource.fileSizeDisplay}'
          '${resource.isLicenseExpired ? " · License expired" : ""}',
          style: tt.bodySmall?.copyWith(
            color: resource.isLicenseExpired
                ? AppColors.error
                : cs.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: cs.error,
            size: Spacings.mdIcon,
          ),
          onPressed: () {
            ref.read(offlineProvider.notifier).removeResource(resource.id);
          },
          tooltip: 'Remove from offline',
        ),
      ),
    );
  }

  String _resourceTypeLabel(String type) {
    const labels = {
      'lesson_note': 'Lesson Notes',
      'worksheet': 'Worksheets',
      'study_guide': 'Study Guides',
      'textbook': 'Textbooks',
      'video': 'Videos',
      'audio': 'Audio',
      'document': 'Documents',
    };
    return labels[type] ?? type.replaceAll('_', ' ').split(' ').map(
      (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
    ).join(' ');
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DOWNLOADS TAB
// ═══════════════════════════════════════════════════════════════════════

class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab({required this.state, required this.onRefresh});

  final OfflineState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = state.downloads;

    if (state.isLoading && downloads.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (downloads.isEmpty) {
      return AppEmptyState.generic(
        icon: Icons.download_outlined,
        message: 'No downloads',
        subtitle: 'Files you download for offline use will appear here',
        onAction: onRefresh,
        actionLabel: 'Refresh',
      );
    }

    // Separate downloads by status
    final active = downloads.where((d) => d.isDownloading || d.downloadStatus == DownloadStatus.pending).toList();
    final completed = downloads.where((d) => d.isComplete).toList();
    final failed = downloads.where((d) => d.canRetry).toList();
    final expired = downloads.where((d) => d.downloadStatus == DownloadStatus.expired).toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active.isNotEmpty) ...[
              _buildDownloadSection(context, 'Active Downloads', active),
              const SizedBox(height: Spacings.lg),
            ],
            if (completed.isNotEmpty) ...[
              _buildDownloadSection(context, 'Completed', completed),
              const SizedBox(height: Spacings.lg),
            ],
            if (failed.isNotEmpty) ...[
              _buildDownloadSection(context, 'Failed', failed),
              const SizedBox(height: Spacings.lg),
            ],
            if (expired.isNotEmpty) ...[
              _buildDownloadSection(context, 'Expired', expired),
            ],
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection(
    BuildContext context,
    String title,
    List<FileDownload> items,
  ) {
    final tt = context.textTheme;
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.sm),
        ...items.map((download) => DownloadProgressCard(
          download: download,
          onCancel: () {
            // Cancel download action
          },
          onRetry: download.canRetry
              ? () {
                  // Retry download action
                }
              : null,
        )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DRAFTS TAB
// ═══════════════════════════════════════════════════════════════════════

class _DraftsTab extends ConsumerWidget {
  const _DraftsTab({required this.state, required this.onRefresh});

  final OfflineState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = state.drafts;

    if (state.isLoading && drafts.isEmpty) {
      return const Center(child: AppLoadingSpinner());
    }

    if (drafts.isEmpty) {
      return AppEmptyState.generic(
        icon: Icons.edit_note_outlined,
        message: 'No drafts',
        subtitle: 'Drafts you create while offline will appear here',
        onAction: onRefresh,
        actionLabel: 'Refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final draft = drafts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: DraftCard(
              draft: draft,
              onEdit: () {
                // Navigate to draft editor
              },
              onDelete: () {
                ref.read(offlineProvider.notifier).deleteDraft(draft.id);
              },
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SYNC TAB
// ═══════════════════════════════════════════════════════════════════════

class _SyncTab extends ConsumerWidget {
  const _SyncTab({required this.state, required this.onRefresh});

  final OfflineState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final sync = state.syncStatus;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Pending Items ────────────────────────────────────────
            _buildSectionHeader(context, 'Pending Sync Items'),
            const SizedBox(height: Spacings.sm),
            Card(
              elevation: Spacings.elevationSm,
              shadowColor: cs.shadow.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: Spacings.borderRadiusLg,
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacings.lg),
                child: Column(
                  children: [
                    _buildSyncItemRow(
                      context,
                      icon: Icons.description_outlined,
                      label: 'Exam Attempts',
                      count: sync?.pendingCount ?? 0,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: Spacings.md),
                    _buildSyncItemRow(
                      context,
                      icon: Icons.edit_note_outlined,
                      label: 'Drafts',
                      count: state.drafts.where((d) => !d.isSynced).length,
                      color: AppColors.info,
                    ),
                    const SizedBox(height: Spacings.md),
                    _buildSyncItemRow(
                      context,
                      icon: Icons.analytics_outlined,
                      label: 'Analytics Events',
                      count: 0,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacings.lg),

            // ─── Failed Items ─────────────────────────────────────────
            if (sync?.failedCount != null && sync!.failedCount > 0) ...[
              _buildSectionHeader(context, 'Failed Items'),
              const SizedBox(height: Spacings.sm),
              Card(
                elevation: Spacings.elevationSm,
                shadowColor: cs.shadow.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: Spacings.borderRadiusLg,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spacings.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: Spacings.mdIcon,
                          ),
                          const SizedBox(width: Spacings.sm),
                          Text(
                            '${sync.failedCount} items failed to sync',
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacings.md),
                      Text(
                        'These items will be retried automatically. You can also retry them manually.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacings.lg),
            ],

            // ─── Action Buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final userId = ref.read(userIdProvider);
                      if (userId != null) {
                        ref.read(offlineProvider.notifier).loadSyncStatus(userId);
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync All'),
                    style: FilledButton.styleFrom(
                      padding: Spacings.paddingButton,
                      shape: RoundedRectangleBorder(
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Failed'),
                    style: OutlinedButton.styleFrom(
                      padding: Spacings.paddingButton,
                      shape: RoundedRectangleBorder(
                        borderRadius: Spacings.borderRadiusMd,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final tt = context.textTheme;
    return Text(
      title,
      style: tt.titleMedium?.copyWith(
        fontWeight: AppTypography.wSemiBold,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSyncItemRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    final tt = context.textTheme;
    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: color),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: Spacings.borderRadiusSm,
          ),
          child: Text(
            '$count',
            style: tt.labelMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
