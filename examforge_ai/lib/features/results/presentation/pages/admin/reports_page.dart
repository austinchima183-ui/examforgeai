import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/results_entities.dart';
import '../providers/results_providers.dart';
import '../providers/results_page_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
// REPORTS PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Admin report generation and export page.
///
/// Allows selecting report type, format, and filters, then generating
/// and downloading reports. Also shows a history of recent reports.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({
    super.key,
    required this.schoolId,
  });

  final String schoolId;

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportType _selectedReportType = ReportType.student;
  ReportFormat _selectedFormat = ReportFormat.pdf;
  String? _selectedClassId;
  String? _selectedSubjectId;
  String? _selectedSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  void _loadReports() {
    ref.read(reportExportProvider.notifier).loadReports(
          schoolId: widget.schoolId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportExportProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Reports',
      ),
      body: state.isLoading && state.reports.isEmpty
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : _buildContent(context, state),
    );
  }

  // ─── Main Content ────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, ReportExportState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Report Configuration ─────────────────────────────
              _buildReportConfig(context, state),
              const SizedBox(height: Spacings.xl),

              // ── Recent Reports ───────────────────────────────────
              _buildRecentReports(context, state),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Report Configuration ────────────────────────────────────────────

  Widget _buildReportConfig(
      BuildContext context, ReportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Generate Report',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.xl),

          // ── Report Type Selector ────────────────────────────────
          Text(
            'Report Type',
            style: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          _buildReportTypeSelector(context),

          const SizedBox(height: Spacings.lg),

          // ── Format Selector ─────────────────────────────────────
          Text(
            'Format',
            style: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          _buildFormatSelector(context),

          const SizedBox(height: Spacings.lg),

          // ── Filters ─────────────────────────────────────────────
          Text(
            'Filters',
            style: tt.labelLarge?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          _buildFilterSection(context),

          const SizedBox(height: Spacings.xl),

          // ── Generate Button ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Generate Report',
              onPressed: state.isGenerating ? null : _generateReport,
              isLoading: state.isGenerating,
              icon: Icons.auto_awesome_rounded,
            ),
          ),

          // Error message
          if (state.error != null) ...[
            const SizedBox(height: Spacings.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: AppColors.errorOf(cs.brightness)
                    .withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: Spacings.mdIcon,
                      color: AppColors.errorOf(cs.brightness)),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.errorOf(cs.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Success message
          if (state.successMessage != null) ...[
            const SizedBox(height: Spacings.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: AppColors.successOf(cs.brightness)
                    .withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: Spacings.mdIcon,
                      color: AppColors.successOf(cs.brightness)),
                  const SizedBox(width: Spacings.sm),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.successOf(cs.brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Report Type Selector ────────────────────────────────────────────

  Widget _buildReportTypeSelector(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final types = ReportType.values;

    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: types.map((type) {
        final isSelected = type == _selectedReportType;
        return ChoiceChip(
          label: Text(type.label),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedReportType = type;
            });
          },
          selectedColor: cs.primary.withValues(alpha: isDark ? 0.25 : 0.12),
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          side: BorderSide(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
          labelStyle: tt.bodySmall?.copyWith(
            fontWeight:
                isSelected ? AppTypography.wBold : AppTypography.wRegular,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
        );
      }).toList(),
    );
  }

  // ─── Format Selector ─────────────────────────────────────────────────

  Widget _buildFormatSelector(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final formats = ReportFormat.values;

    return Wrap(
      spacing: Spacings.sm,
      runSpacing: Spacings.sm,
      children: formats.map((format) {
        final isSelected = format == _selectedFormat;
        final icon = switch (format) {
          ReportFormat.pdf => Icons.picture_as_pdf_rounded,
          ReportFormat.excel => Icons.table_chart_rounded,
          ReportFormat.csv => Icons.data_table_rounded,
        };
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Spacings.smIcon,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(format.label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedFormat = format;
            });
          },
          selectedColor: cs.primary.withValues(alpha: isDark ? 0.25 : 0.12),
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          side: BorderSide(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
          labelStyle: tt.bodySmall?.copyWith(
            fontWeight:
                isSelected ? AppTypography.wBold : AppTypography.wRegular,
            color: isSelected ? cs.primary : cs.onSurfaceVariant,
          ),
        );
      }).toList(),
    );
  }

  // ─── Filter Section ──────────────────────────────────────────────────

  Widget _buildFilterSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;

      if (isWide) {
        return Row(
          children: [
            Expanded(child: _buildFilterDropdown(
              context,
              label: 'Class',
              hint: 'Select class',
              value: _selectedClassId,
              items: const [
                // TODO: Load from data source
              ],
              onChanged: (v) => setState(() => _selectedClassId = v),
            )),
            const SizedBox(width: Spacings.md),
            Expanded(child: _buildFilterDropdown(
              context,
              label: 'Subject',
              hint: 'Select subject',
              value: _selectedSubjectId,
              items: const [
                // TODO: Load from data source
              ],
              onChanged: (v) => setState(() => _selectedSubjectId = v),
            )),
            const SizedBox(width: Spacings.md),
            Expanded(child: _buildFilterDropdown(
              context,
              label: 'Session',
              hint: 'Select session',
              value: _selectedSessionId,
              items: const [
                // TODO: Load from data source
              ],
              onChanged: (v) => setState(() => _selectedSessionId = v),
            )),
          ],
        );
      }

      return Column(
        children: [
          _buildFilterDropdown(
            context,
            label: 'Class',
            hint: 'Select class',
            value: _selectedClassId,
            items: const [],
            onChanged: (v) => setState(() => _selectedClassId = v),
          ),
          const SizedBox(height: Spacings.sm),
          _buildFilterDropdown(
            context,
            label: 'Subject',
            hint: 'Select subject',
            value: _selectedSubjectId,
            items: const [],
            onChanged: (v) => setState(() => _selectedSubjectId = v),
          ),
          const SizedBox(height: Spacings.sm),
          _buildFilterDropdown(
            context,
            label: 'Session',
            hint: 'Select session',
            value: _selectedSessionId,
            items: const [],
            onChanged: (v) => setState(() => _selectedSessionId = v),
          ),
        ],
      );
    });
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacings.xs),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          )),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
          ),
          items: [
            ...items,
            // Placeholder item to show the dropdown works
            if (items.isEmpty)
              const DropdownMenuItem<String>(
                value: null,
                enabled: false,
                child: Text('No options available'),
              ),
          ],
          onChanged: items.isNotEmpty ? onChanged : null,
        ),
      ],
    );
  }

  // ─── Generate Report ─────────────────────────────────────────────────

  void _generateReport() {
    final titleSuffix = switch (_selectedReportType) {
      ReportType.student => 'Student Report',
      ReportType.classReport => 'Class Report',
      ReportType.school => 'School Report',
      ReportType.subject => 'Subject Report',
      ReportType.examSummary => 'Exam Summary',
    };

    final timestamp = DateTime.now().toIso8601String().substring(0, 10);

    ref.read(reportExportProvider.notifier).createReport(
          schoolId: widget.schoolId,
          requestedBy: 'admin', // TODO: Use actual admin user ID
          reportType: _selectedReportType,
          reportFormat: _selectedFormat,
          title: '$titleSuffix - $timestamp',
          filters: {
            if (_selectedClassId != null) 'classId': _selectedClassId,
            if (_selectedSubjectId != null) 'subjectId': _selectedSubjectId,
            if (_selectedSessionId != null)
              'academicSessionId': _selectedSessionId,
          },
        );
  }

  // ─── Recent Reports ──────────────────────────────────────────────────

  Widget _buildRecentReports(
      BuildContext context, ReportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final reports = state.reports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded,
                size: Spacings.mdIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.sm),
            Text(
              'Recent Reports',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            if (reports.isNotEmpty)
              Text(
                '${reports.length} report${reports.length == 1 ? '' : 's'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        if (reports.isEmpty)
          AppCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacings.xl),
                child: AppEmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'No Reports Yet',
                  subtitle:
                      'Generated reports will appear here for download.',
                ),
              ),
            ),
          )
        else
          ...reports.map((report) => Padding(
                padding: const EdgeInsets.only(bottom: Spacings.md),
                child: _buildReportItem(context, report),
              )),
      ],
    );
  }

  Widget _buildReportItem(
      BuildContext context, ReportExportEntity report) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final formatColor = switch (report.reportFormat) {
      ReportFormat.pdf => AppColors.errorOf(cs.brightness),
      ReportFormat.excel => AppColors.successOf(cs.brightness),
      ReportFormat.csv => AppColors.infoOf(cs.brightness),
    };

    final statusColor = switch (report.status) {
      ReportStatus.pending => AppColors.warningOf(cs.brightness),
      ReportStatus.processing => cs.primary,
      ReportStatus.completed => AppColors.successOf(cs.brightness),
      ReportStatus.failed => AppColors.errorOf(cs.brightness),
    };

    final statusIcon = switch (report.status) {
      ReportStatus.pending => Icons.schedule_rounded,
      ReportStatus.processing => Icons.sync_rounded,
      ReportStatus.completed => Icons.check_circle_rounded,
      ReportStatus.failed => Icons.error_rounded,
    };

    return AppCard(
      child: Row(
        children: [
          // Format icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: formatColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Center(
              child: Icon(
                switch (report.reportFormat) {
                  ReportFormat.pdf => Icons.picture_as_pdf_rounded,
                  ReportFormat.excel => Icons.table_chart_rounded,
                  ReportFormat.csv => Icons.data_table_rounded,
                },
                size: Spacings.mdIcon,
                color: formatColor,
              ),
            ),
          ),
          const SizedBox(width: Spacings.md),

          // Report info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary
                            .withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        report.reportType.label,
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    // Format badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            formatColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        report.reportFormat.label,
                        style: tt.labelSmall?.copyWith(
                          color: formatColor,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            report.status.label,
                            style: tt.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  _formatDateTime(report.createdAt),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: Spacings.sm),

          // Download button
          if (report.status == ReportStatus.completed)
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: cs.primary,
              ),
              tooltip: 'Download',
              onPressed: () => _downloadReport(report),
            )
          else if (report.status == ReportStatus.processing)
            const SizedBox(
              width: Spacings.mdIcon,
              height: Spacings.mdIcon,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  // ─── Download Report ─────────────────────────────────────────────────

  void _downloadReport(ReportExportEntity report) {
    ref.read(reportExportProvider.notifier).downloadReport(report.id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }
}
