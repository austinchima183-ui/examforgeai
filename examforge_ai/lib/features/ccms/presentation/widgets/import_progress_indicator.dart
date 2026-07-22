import 'package:flutter/material.dart';

import '../../../../../core/core.dart';
import '../../domain/entities/ccms_entities.dart';

/// Progress bar showing import status with detailed counts.
///
/// Features:
/// - Total / Processed / Successful / Failed counts
/// - Progress bar with color: green for success, red for failed
/// - Status text
/// - Percentage display
class ImportProgressIndicator extends StatelessWidget {
  const ImportProgressIndicator({
    super.key,
    required this.importEntry,
    this.compact = false,
  });

  /// The import entry to display progress for.
  final ContentImport importEntry;

  /// When true, shows a compact single-line view.
  final bool compact;

  // ─── Computed Values ────────────────────────────────────────────────────

  double get _progress {
    if (importEntry.totalItems == 0) return 0;
    return (importEntry.processedItems / importEntry.totalItems).clamp(0.0, 1.0);
  }

  double get _successRate {
    if (importEntry.processedItems == 0) return 0;
    final successful = importEntry.processedItems - importEntry.failedItems;
    return (successful / importEntry.processedItems).clamp(0.0, 1.0);
  }

  String get _percentage {
    return '${(_progress * 100).toStringAsFixed(1)}%';
  }

  // ─── Status Helpers ─────────────────────────────────────────────────────

  Color _statusColor() {
    return switch (importEntry.status) {
      ImportStatus.pending => AppColors.warning,
      ImportStatus.processing => AppColors.info,
      ImportStatus.completed => AppColors.success,
      ImportStatus.failed => AppColors.error,
      ImportStatus.partiallyCompleted => const Color(0xFFF97316), // orange
    };
  }

  IconData _statusIcon() {
    return switch (importEntry.status) {
      ImportStatus.pending => Icons.schedule_rounded,
      ImportStatus.processing => Icons.sync_rounded,
      ImportStatus.completed => Icons.check_circle_rounded,
      ImportStatus.failed => Icons.error_rounded,
      ImportStatus.partiallyCompleted => Icons.warning_rounded,
    };
  }

  String _statusText() {
    return switch (importEntry.status) {
      ImportStatus.pending => 'Waiting to start...',
      ImportStatus.processing => 'Importing content...',
      ImportStatus.completed => 'Import completed successfully',
      ImportStatus.failed => 'Import failed',
      ImportStatus.partiallyCompleted => 'Import partially completed',
    };
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final color = _statusColor();
    final successfulItems = importEntry.successfulItems;

    // ── Compact mode ─────────────────────────────────────────────────────
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(), size: 16, color: color),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: Spacings.borderRadiusSm,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 4,
                backgroundColor: cs.surfaceContainerHighest,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: Spacings.sm),
          Text(
            _percentage,
            style: tt.bodySmall?.copyWith(
              color: color,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ],
      );
    }

    // ── Full mode ────────────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status header ─────────────────────────────────────────────
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(Spacings.xs),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.20 : 0.12),
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Icon(_statusIcon(), size: Spacings.mdIcon, color: color),
            ),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    importEntry.status.label,
                    style: tt.labelMedium?.copyWith(
                      color: color,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                  Text(
                    _statusText(),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Percentage display
            Text(
              _percentage,
              style: tt.titleMedium?.copyWith(
                color: color,
                fontWeight: AppTypography.wBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // ── Progress bar ──────────────────────────────────────────────
        Stack(
          children: [
            // Background track
            ClipRRect(
              borderRadius: Spacings.borderRadiusSm,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                color: AppColors.success,
              ),
            ),
            // Failed overlay (shows red portion for failed items)
            if (importEntry.failedItems > 0 && importEntry.totalItems > 0)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: FractionallySizedBox(
                  widthFactor: importEntry.failedItems / importEntry.totalItems,
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                          importEntry.failedItems >= importEntry.totalItems
                              ? Spacings.smRadius
                              : 0,
                        ),
                        bottomRight: Radius.circular(
                          importEntry.failedItems >= importEntry.totalItems
                              ? Spacings.smRadius
                              : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // ── Count statistics ──────────────────────────────────────────
        Row(
          children: [
            _StatChip(
              label: 'Total',
              value: '${importEntry.totalItems}',
              color: cs.onSurfaceVariant,
              isDark: isDark,
            ),
            const SizedBox(width: Spacings.sm),
            _StatChip(
              label: 'Processed',
              value: '${importEntry.processedItems}',
              color: AppColors.info,
              isDark: isDark,
            ),
            const SizedBox(width: Spacings.sm),
            _StatChip(
              label: 'Successful',
              value: '$successfulItems',
              color: AppColors.success,
              isDark: isDark,
            ),
            if (importEntry.failedItems > 0) ...[
              const SizedBox(width: Spacings.sm),
              _StatChip(
                label: 'Failed',
                value: '${importEntry.failedItems}',
                color: AppColors.error,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: Spacings.borderRadiusSm,
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.labelSmall!.copyWith(
              color: color,
              fontWeight: AppTypography.wBold,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption!.copyWith(
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
