import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/parent_reports_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// PARENT REPORTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Reports & Downloads page for the Parent Portal.
///
/// Displays available reports (Report Card, Attendance, Assignments,
/// Academic Progress) with format selector dropdowns and download
/// buttons, plus a download history section with re-download options.
///
/// Uses [ConsumerStatefulWidget] with a private [_State] class pattern,
/// and renders a responsive layout using [Scaffold] with [AppAppBar].
class ParentReportsPage extends ConsumerStatefulWidget {
  const ParentReportsPage({super.key});

  @override
  ConsumerState<ParentReportsPage> createState() => _State();
}

class _State extends ConsumerState<ParentReportsPage> {
  // ─── State ──────────────────────────────────────────────────────────

  /// The selected child for reports.
  String? _selectedChildId;

  /// Selected format per report type.
  final Map<String, String> _selectedFormats = {};

  // ─── Available report types with their details.
  static const _reportTypes = <_ReportTypeEntry>[
    _ReportTypeEntry(
      type: 'report_card',
      label: 'Report Card',
      icon: Icons.description_outlined,
      description: 'Complete academic report card with grades and remarks',
    ),
    _ReportTypeEntry(
      type: 'attendance',
      label: 'Attendance Report',
      icon: Icons.calendar_today_outlined,
      description: 'Attendance summary and daily breakdown',
    ),
    _ReportTypeEntry(
      type: 'assignments',
      label: 'Assignment Report',
      icon: Icons.assignment_outlined,
      description: 'All assignments with submission status and scores',
    ),
    _ReportTypeEntry(
      type: 'progress',
      label: 'Academic Progress Report',
      icon: Icons.trending_up_outlined,
      description: 'Longitudinal progress across subjects and terms',
    ),
  ];

  /// Available download formats.
  static const _formats = ['PDF', 'Excel', 'Printable'];

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(parentReportsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Reports & Downloads',
      ),
      body: _buildBody(context, reportsState),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBody(BuildContext context, ParentReportsState state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: Spacings.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Child Selector ─────────────────────────────────────
          _buildChildSelector(context),

          const SizedBox(height: Spacings.lg),

          // ─── Download Progress ──────────────────────────────────
          if (state.isDownloading) _buildDownloadProgress(context, state),

          // ─── Error Message ──────────────────────────────────────
          if (state.error != null) _buildErrorMessage(context, state),

          // ─── Available Reports ──────────────────────────────────
          _buildAvailableReports(context, state),

          const SizedBox(height: Spacings.xl),

          // ─── Download History ───────────────────────────────────
          _buildDownloadHistory(context, state),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHILD SELECTOR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildChildSelector(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedChildId,
        decoration: InputDecoration(
          labelText: 'Select Child',
          labelStyle: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: Spacings.borderRadiusMd,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Spacings.lg,
            vertical: Spacings.md,
          ),
        ),
        items: [
          // TODO: Populate with actual children from dashboard state
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Children'),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedChildId = value);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOWNLOAD PROGRESS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDownloadProgress(
    BuildContext context,
    ParentReportsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Card(
        elevation: Spacings.elevationNone,
        color: AppColors.infoOf(cs.brightness).withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Text(
                  'Downloading report…',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: AppTypography.wMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ERROR MESSAGE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildErrorMessage(
    BuildContext context,
    ParentReportsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.lg,
        vertical: Spacings.sm,
      ),
      child: Card(
        elevation: Spacings.elevationNone,
        color: AppColors.errorOf(cs.brightness).withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.errorOf(cs.brightness),
                size: Spacings.mdIcon,
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Text(
                  state.error!,
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.errorOf(cs.brightness),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: () =>
                    ref.read(parentReportsProvider.notifier).clearError(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AVAILABLE REPORTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAvailableReports(
    BuildContext context,
    ParentReportsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Reports',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          ..._reportTypes.map((report) => _buildReportCard(
                context,
                report,
                state,
              )),
        ],
      ),
    );
  }

  // ─── Report Card ────────────────────────────────────────────────────

  Widget _buildReportCard(
    BuildContext context,
    _ReportTypeEntry report,
    ParentReportsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final selectedFormat = _selectedFormats[report.type] ?? 'PDF';

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              // Report icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(
                  report.icon,
                  color: cs.primary,
                  size: Spacings.mdIcon,
                ),
              ),
              const SizedBox(width: Spacings.md),

              // Report details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.label,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      report.description,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.sm),
                    // Format selector + Download button
                    Row(
                      children: [
                        // Format dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: Spacings.borderRadiusSm,
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: selectedFormat,
                            underline: const SizedBox.shrink(),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              size: Spacings.smIcon,
                              color: cs.onSurfaceVariant,
                            ),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurface,
                            ),
                            items: _formats.map((format) {
                              return DropdownMenuItem<String>(
                                value: format,
                                child: Text(format),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFormats[report.type] = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        // Download button
                        FilledButton.icon(
                          onPressed: state.isDownloading
                              ? null
                              : () => _downloadReport(
                                    report.type,
                                    selectedFormat,
                                  ),
                          icon: Icon(
                            Icons.download,
                            size: Spacings.smIcon,
                          ),
                          label: Text(
                            'Download',
                            style: tt.labelMedium?.copyWith(
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacings.md,
                              vertical: Spacings.sm,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DOWNLOAD HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDownloadHistory(
    BuildContext context,
    ParentReportsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final downloads = state.downloads;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download History',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          if (downloads.isEmpty)
            AppEmptyState.noData(
              title: 'No Downloads Yet',
              subtitle: 'Your downloaded reports will appear here.',
            )
          else
            ...downloads.map((download) => _buildHistoryCard(
                  context,
                  download,
                  state,
                )),
        ],
      ),
    );
  }

  // ─── History Card ───────────────────────────────────────────────────

  Widget _buildHistoryCard(
    BuildContext context,
    ParentReportDownloadEntity download,
    ParentReportsState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Card(
        elevation: Spacings.elevationNone,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusMd,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Row(
            children: [
              // File icon
              Icon(
                _formatIcon(download.format),
                color: cs.onSurfaceVariant,
                size: Spacings.mdIcon,
              ),
              const SizedBox(width: Spacings.md),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      download.reportType.label,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Row(
                      children: [
                        // Format badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: Spacings.borderRadiusSm,
                          ),
                          child: Text(
                            download.format.toUpperCase(),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        // Date
                        Text(
                          _formatDate(download.downloadedAt),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (download.fileSizeBytes != null) ...[
                          const SizedBox(width: Spacings.sm),
                          Text(
                            _formatFileSize(download.fileSizeBytes!),
                            style: tt.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Re-download button
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: cs.primary,
                  size: Spacings.mdIcon,
                ),
                onPressed: state.isDownloading
                    ? null
                    : () => _downloadReport(
                          download.reportType.value,
                          download.format,
                        ),
                tooltip: 'Re-download',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Triggers a report download.
  void _downloadReport(String reportType, String format) {
    // Use a placeholder student ID; in production this comes from the
    // child selector.
    const studentId = 'current_student';
    ref.read(parentReportsProvider.notifier).downloadReport(
      studentId,
      reportType,
      format.toLowerCase(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════

  /// Returns the icon for a file format.
  IconData _formatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'excel':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'printable':
        return Icons.print_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Formats a [DateTime] as a short date string.
  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  /// Formats file size in bytes as a human-readable string.
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// A data holder for a report type entry.
class _ReportTypeEntry {
  const _ReportTypeEntry({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });

  /// The report type key.
  final String type;

  /// Display label for the report type.
  final String label;

  /// Icon for the report type.
  final IconData icon;

  /// Short description of the report content.
  final String description;
}
