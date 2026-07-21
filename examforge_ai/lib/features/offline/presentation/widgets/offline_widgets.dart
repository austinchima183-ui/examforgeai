import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/offline_entities.dart';

// ============================================================================
// 1. CONNECTIVITY BANNER
// ============================================================================

/// A colored banner shown at the top of the screen when offline or limited.
///
/// - **Red**: Offline — no internet connection
/// - **Orange**: Limited — poor connection quality
///
/// Tapping the banner can navigate to the connectivity details page.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({
    super.key,
    required this.connectivityInfo,
    this.onTap,
  });

  final ConnectivityInfo connectivityInfo;
  final VoidCallback? onTap;

  /// Whether the banner should be shown.
  bool get shouldShow =>
      !connectivityInfo.isOnline ||
      connectivityInfo.connectionQuality == ConnectionQuality.limited;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    final isOffline = !connectivityInfo.isOnline;
    final backgroundColor = isOffline ? AppColors.error : AppColors.warning;
    final textColor = Colors.white;
    final icon = isOffline ? Icons.cloud_off : Icons.signal_cellular_alt;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.sm,
            ),
            child: Row(
              children: [
                Icon(icon, size: Spacings.mdIcon, color: textColor),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    isOffline
                        ? 'You are offline. Some features may be limited.'
                        : 'Limited connection. Syncing may be delayed.',
                    style: AppTypography.buttonSmall.copyWith(color: textColor),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: Spacings.mdIcon,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. SYNC STATUS CHIP
// ============================================================================

/// Status variant for the sync chip.
enum SyncChipStatus {
  synced,
  pending,
  conflict,
}

/// A small chip showing the current sync status.
///
/// - **Synced** (green): All items are synced
/// - **Pending** (amber): Items are waiting to sync
/// - **Conflict** (red): There are sync conflicts
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.syncStatus,
    this.label,
  });

  final SyncChipStatus syncStatus;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final icon = _statusIcon;
    final text = label ?? _statusLabel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Spacings.smIcon + 2, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            text,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (syncStatus) {
      case SyncChipStatus.synced:
        return AppColors.success;
      case SyncChipStatus.pending:
        return AppColors.warning;
      case SyncChipStatus.conflict:
        return AppColors.error;
    }
  }

  IconData get _statusIcon {
    switch (syncStatus) {
      case SyncChipStatus.synced:
        return Icons.check_circle;
      case SyncChipStatus.pending:
        return Icons.schedule;
      case SyncChipStatus.conflict:
        return Icons.error;
    }
  }

  String get _statusLabel {
    switch (syncStatus) {
      case SyncChipStatus.synced:
        return 'Synced';
      case SyncChipStatus.pending:
        return 'Pending';
      case SyncChipStatus.conflict:
        return 'Conflict';
    }
  }
}

// ============================================================================
// 3. OFFLINE INDICATOR
// ============================================================================

/// An icon badge showing whether a resource is available offline.
///
/// Displays a green download icon with a check when available,
/// or a grey cloud-off icon when not.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({
    super.key,
    required this.isAvailable,
    this.size = Spacings.lgIcon,
  });

  final bool isAvailable;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withValues(alpha: 0.1)
            : context.colorScheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isAvailable ? Icons.download_done : Icons.cloud_off_outlined,
        size: size * 0.6,
        color: isAvailable
            ? AppColors.success
            : context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ============================================================================
// 4. DOWNLOAD PROGRESS CARD
// ============================================================================

/// A card showing download progress with cancel/retry buttons.
///
/// Displays the file name, size, progress bar, and status-appropriate
/// action buttons:
/// - **Downloading**: Cancel button
/// - **Failed**: Retry button
/// - **Completed**: No action
/// - **Expired**: Indicator
class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({
    super.key,
    required this.download,
    this.onCancel,
    this.onRetry,
  });

  final FileDownload download;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
        padding: const EdgeInsets.all(Spacings.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    download.fileName,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: Spacings.xs),

            // ── Size ────────────────────────────────────────────────────
            Text(
              download.fileSizeDisplay,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacings.sm),

            // ── Progress Bar ────────────────────────────────────────────
            if (download.isDownloading || download.downloadStatus == DownloadStatus.pending) ...[
              ClipRRect(
                borderRadius: Spacings.borderRadiusFull,
                child: LinearProgressIndicator(
                  value: download.isDownloading ? download.progress : null,
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
              const SizedBox(height: Spacings.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    download.isDownloading ? download.progressPercent : 'Queued',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: tt.labelSmall?.copyWith(color: cs.error),
                      ),
                    ),
                ],
              ),
            ],

            // ── Failed Actions ──────────────────────────────────────────
            if (download.canRetry && onRetry != null) ...[
              const SizedBox(height: Spacings.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: Spacings.smIcon + 4),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = _statusColor;
    final label = download.downloadStatus.label;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
          color: color,
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (download.downloadStatus) {
      case DownloadStatus.pending:
        return AppColors.info;
      case DownloadStatus.downloading:
        return AppColors.info;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.expired:
        return AppColors.warning;
    }
  }
}

// ============================================================================
// 5. DRAFT CARD
// ============================================================================

/// A card showing a saved draft with type icon, title, and last edited time.
///
/// Includes edit and delete action buttons.
class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.draft,
    this.onEdit,
    this.onDelete,
  });

  final DraftWork draft;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Card(
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacings.md),
        child: Row(
          children: [
            // ── Type Icon ────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: Spacings.borderRadiusMd,
              ),
              child: Icon(
                _typeIcon,
                size: Spacings.mdIcon,
                color: isDark ? _typeColor : _typeColor,
              ),
            ),
            const SizedBox(width: Spacings.md),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          draft.title,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: AppTypography.wMedium,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!draft.isSynced) ...[
                        const SizedBox(width: Spacings.xs),
                        Icon(
                          Icons.cloud_off,
                          size: Spacings.smIcon,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '${draft.draftType.label} · ${_formatTimeSince(draft.lastEditedAt)}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ─────────────────────────────────────────────────
            const SizedBox(width: Spacings.sm),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: Spacings.mdIcon),
                onPressed: onEdit,
                tooltip: 'Edit draft',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: Spacings.mdIcon,
                  color: cs.error,
                ),
                onPressed: onDelete,
                tooltip: 'Delete draft',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (draft.draftType) {
      case DraftType.exam:
        return Icons.quiz_outlined;
      case DraftType.assignment:
        return Icons.assignment_outlined;
      case DraftType.lessonPlan:
        return Icons.menu_book_outlined;
      case DraftType.question:
        return Icons.help_outline;
      case DraftType.resource:
        return Icons.folder_outlined;
    }
  }

  Color get _typeColor {
    switch (draft.draftType) {
      case DraftType.exam:
        return AppColors.info;
      case DraftType.assignment:
        return const Color(0xFF8B5CF6); // Violet
      case DraftType.lessonPlan:
        return AppColors.success;
      case DraftType.question:
        return AppColors.warning;
      case DraftType.resource:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  String _formatTimeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ============================================================================
// 6. STORAGE USAGE BAR
// ============================================================================

/// A progress bar showing local storage usage.
///
/// Displays a linear bar with a label underneath showing the used/total
/// amount, and a percentage indicator.
class StorageUsageBar extends StatelessWidget {
  const StorageUsageBar({
    super.key,
    required this.usedBytes,
    required this.totalBytes,
    this.label,
  });

  final int usedBytes;
  final int totalBytes;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final ratio = totalBytes > 0 ? usedBytes / totalBytes : 0.0;
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final percent = (clampedRatio * 100).toStringAsFixed(0);

    final barColor = ratio > 0.9
        ? AppColors.error
        : ratio > 0.7
            ? AppColors.warning
            : AppColors.success;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label ?? '${_formatBytes(usedBytes)} / ${_formatBytes(totalBytes)}',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wMedium,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '$percent%',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            ClipRRect(
              borderRadius: Spacings.borderRadiusFull,
              child: LinearProgressIndicator(
                value: clampedRatio,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
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

// ============================================================================
// 7. CONNECTION QUALITY INDICATOR
// ============================================================================

/// An animated indicator showing the current connection quality.
///
/// Displays concentric arcs (like a Wi-Fi signal) that fill based on
/// the connection quality level:
/// - **Excellent**: 4 arcs, green
/// - **Good**: 3 arcs, blue
/// - **Limited**: 2 arcs, orange
/// - **Offline**: 0 arcs, red with a cross
class ConnectionQualityIndicator extends StatefulWidget {
  const ConnectionQualityIndicator({
    super.key,
    required this.quality,
    this.size = 40,
  });

  final ConnectionQuality? quality;
  final double size;

  @override
  State<ConnectionQualityIndicator> createState() =>
      _ConnectionQualityIndicatorState();
}

class _ConnectionQualityIndicatorState
    extends State<ConnectionQualityIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ConnectionQualityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quality != widget.quality) {
      _controller.reset();
      if (widget.quality != ConnectionQuality.offline) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quality = widget.quality ?? ConnectionQuality.offline;
    final color = _qualityColor(quality);
    final arcCount = _arcCount(quality);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulseValue = quality == ConnectionQuality.offline
            ? 1.0
            : 0.85 + (_controller.value * 0.15);

        return Transform.scale(
          scale: pulseValue,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SignalArcPainter(
              arcCount: arcCount,
              color: color,
              isOffline: quality == ConnectionQuality.offline,
            ),
          ),
        );
      },
    );
  }

  int _arcCount(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 4;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.limited:
        return 2;
      case ConnectionQuality.offline:
        return 0;
    }
  }

  Color _qualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return AppColors.success;
      case ConnectionQuality.good:
        return AppColors.info;
      case ConnectionQuality.limited:
        return AppColors.warning;
      case ConnectionQuality.offline:
        return AppColors.error;
    }
  }
}

/// Custom painter for the signal arc indicator.
class _SignalArcPainter extends CustomPainter {
  _SignalArcPainter({
    required this.arcCount,
    required this.color,
    required this.isOffline,
  });

  final int arcCount;
  final Color color;
  final bool isOffline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final baseRadius = size.width * 0.15;

    if (isOffline) {
      // Draw an X for offline
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final crossSize = size.width * 0.25;
      canvas.drawLine(
        Offset(center.dx - crossSize, center.dy - crossSize),
        Offset(center.dx + crossSize, center.dy + crossSize),
        paint,
      );
      canvas.drawLine(
        Offset(center.dx + crossSize, center.dy - crossSize),
        Offset(center.dx - crossSize, center.dy + crossSize),
        paint,
      );
      return;
    }

    // Draw signal arcs
    for (int i = 0; i < 4; i++) {
      final radius = baseRadius + (i * size.width * 0.12);
      final isActive = i < arcCount;
      final paint = Paint()
        ..color = isActive ? color : color.withValues(alpha: 0.15)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -2.2, // ~-126 degrees
        1.4, // ~80 degrees sweep
        false,
        paint,
      );
    }

    // Draw center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(_SignalArcPainter oldDelegate) {
    return arcCount != oldDelegate.arcCount ||
        color != oldDelegate.color ||
        isOffline != oldDelegate.isOffline;
  }
}
