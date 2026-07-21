import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_search_bar.dart';
import '../../domain/entities/school_management_entities.dart';
import '../../providers/report_provider.dart';
import '../../providers/class_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// STUDENT REPORT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Student list report with filters, table view, and export buttons.
///
/// Table columns: name, admission #, class, gender, attendance rate,
/// average score. Class filter, search. Export to PDF/Excel (future-ready).
class StudentReportPage extends ConsumerStatefulWidget {
  const StudentReportPage({super.key});

  @override
  ConsumerState<StudentReportPage> createState() => _StudentReportPageState();
}

class _StudentReportPageState extends ConsumerState<StudentReportPage> {
  final _searchController = TextEditingController();
  String? _selectedClassId;
  bool _isSearchMode = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportProvider.notifier).loadStudentReport(
            schoolId: 'current-school',
          );
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(reportProvider);
    final classState = ref.watch(classListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Student Report',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() => _isSearchMode = !_isSearchMode);
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterSheet(context, classState.classes),
            tooltip: 'Filter by class',
          ),
        ],
        bottom: _isSearchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  child: AppSearchBar(
                    hint: 'Search by student name or admission #...',
                    controller: _searchController,
                    onChanged: (query) {
                      // Future: filter locally
                    },
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ReportState state) {
    if (state.isLoading && !state.hasStudentReport) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && !state.hasStudentReport) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(reportProvider.notifier).loadStudentReport(
              schoolId: 'current-school',
              classId: _selectedClassId,
            ),
      );
    }

    if (state.studentReport.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Student Data',
        subtitle: 'Student report data will appear here once available.',
      );
    }

    return Column(
      children: [
        // ─── Summary bar ────────────────────────────────────────────
        _buildSummaryBar(context, state),

        // ─── Data table ─────────────────────────────────────────────
        Expanded(child: _buildDataTable(context, state)),
      ],
    );
  }

  // ─── Summary Bar ───────────────────────────────────────────────────

  Widget _buildSummaryBar(BuildContext context, ReportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final totalStudents = state.studentReport.length;
    final avgAttendance = state.studentReport.isEmpty
        ? 0.0
        : state.studentReport
                .map((s) => (s['attendanceRate'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a + b) /
            totalStudents;
    final avgScore = state.studentReport.isEmpty
        ? 0.0
        : state.studentReport
                .map((s) => (s['averageScore'] as num?)?.toDouble() ?? 0.0)
                .reduce((a, b) => a + b) /
            totalStudents;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      color: cs.surfaceContainerLow,
      child: Row(
        children: [
          _SummaryChip(
            label: 'Students',
            value: '$totalStudents',
            icon: Icons.people_rounded,
            color: AppColors.seed,
          ),
          const SizedBox(width: Spacings.lg),
          _SummaryChip(
            label: 'Avg Attendance',
            value: '${avgAttendance.toStringAsFixed(1)}%',
            icon: Icons.how_to_reg_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: Spacings.lg),
          _SummaryChip(
            label: 'Avg Score',
            value: avgScore.toStringAsFixed(1),
            icon: Icons.grade_rounded,
            color: AppColors.info,
          ),
          const Spacer(),
          // ─── Export buttons ──────────────────────────────────────
          _ExportButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            isExporting: _isExporting,
            onPressed: () => _exportReport('pdf'),
          ),
          const SizedBox(width: Spacings.sm),
          _ExportButton(
            label: 'Excel',
            icon: Icons.table_chart_outlined,
            isExporting: _isExporting,
            onPressed: () => _exportReport('excel'),
          ),
        ],
      ),
    );
  }

  // ─── Data Table ────────────────────────────────────────────────────

  Widget _buildDataTable(BuildContext context, ReportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHigh),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 64,
          columns: [
            DataColumn(
              label: Text(
                'Name',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Admission #',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Class',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Gender',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Attendance %',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Avg Score',
                style: tt.labelMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              numeric: true,
            ),
          ],
          rows: state.studentReport.map((student) {
            final attendanceRate =
                (student['attendanceRate'] as num?)?.toDouble() ?? 0.0;
            final avgScore =
                (student['averageScore'] as num?)?.toDouble() ?? 0.0;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    student['name'] as String? ?? '—',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wMedium,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    student['admissionNumber'] as String? ?? '—',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                ),
                DataCell(
                  Text(
                    student['className'] as String? ?? '—',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                ),
                DataCell(
                  Text(
                    student['gender'] as String? ?? '—',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                ),
                DataCell(
                  _AttendanceIndicator(rate: attendanceRate),
                ),
                DataCell(
                  Text(
                    avgScore.toStringAsFixed(1),
                    style: tt.bodyMedium?.copyWith(
                      color: _scoreColor(avgScore),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  // ─── Export ────────────────────────────────────────────────────────

  Future<void> _exportReport(String format) async {
    setState(() => _isExporting = true);
    // Simulate export delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export to ${format.toUpperCase()} completed (placeholder).')),
      );
    }
  }

  // ─── Filter Sheet ──────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, List<ClassEntity> classes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(Spacings.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Class',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Classes'),
                  ),
                  ...classes.map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedClassId = value);
                  setModalState(() => _selectedClassId = value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply Filter',
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(reportProvider.notifier).loadStudentReport(
                          schoolId: 'current-school',
                          classId: _selectedClassId,
                        );
                  },
                  variant: AppButtonVariant.elevated,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Spacings.smIcon, color: color),
        const SizedBox(width: Spacings.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: color,
              ),
            ),
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.isExporting,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isExporting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isExporting ? null : onPressed,
      icon: isExporting
          ? SizedBox(
              width: Spacings.smIcon,
              height: Spacings.smIcon,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: Spacings.smIcon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: Spacings.md, vertical: Spacings.sm),
        textStyle: context.textTheme.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

class _AttendanceIndicator extends StatelessWidget {
  const _AttendanceIndicator({required this.rate});

  final double rate;

  Color _color() {
    if (rate >= 90) return AppColors.success;
    if (rate >= 75) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: rate / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Spacings.fullRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.sm),
        Text(
          '${rate.toStringAsFixed(1)}%',
          style: context.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
      ],
    );
  }
}
