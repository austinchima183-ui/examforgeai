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
import '../../domain/entities/school_management_entities.dart';
import '../../providers/report_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/academic_session_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// ATTENDANCE REPORT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Attendance report page with class filter, term filter, date range,
/// summary statistics, per-class breakdown, and student-level detail
/// with high/low attendance indicators. Export button.
class AttendanceReportPage extends ConsumerStatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  ConsumerState<AttendanceReportPage> createState() =>
      _AttendanceReportPageState();
}

class _AttendanceReportPageState extends ConsumerState<AttendanceReportPage> {
  String? _selectedClassId;
  String? _selectedTermId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  bool _showStudentDetail = false;
  String? _expandedClassId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classListProvider.notifier).loadClasses(schoolId: 'current-school');
      ref.read(reportProvider.notifier).loadAttendanceReport(
            schoolId: 'current-school',
            termId: 'current-term',
          );
    });
  }

  // ─── Date Pickers ──────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      _refreshReport();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      _refreshReport();
    }
  }

  void _refreshReport() {
    ref.read(reportProvider.notifier).loadAttendanceReport(
          schoolId: 'current-school',
          termId: _selectedTermId ?? 'current-term',
          classId: _selectedClassId,
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, "0")}, ${date.year}';
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
        title: Text(
          'Attendance Report',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: cs.onSurfaceVariant),
            onPressed: () => _showFilterSheet(context, classState.classes),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ReportState state) {
    if (state.isLoading && !state.hasAttendanceReport) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && !state.hasAttendanceReport) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => _refreshReport(),
      );
    }

    if (state.attendanceReport.isEmpty) {
      return AppEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Attendance Data',
        subtitle: 'Attendance report data will appear here once available.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshReport(),
      child: CustomScrollView(
        slivers: [
          // ─── Summary Statistics ──────────────────────────────────
          SliverToBoxAdapter(child: _buildSummaryStats(context, state)),

          // ─── Per-Class Breakdown ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacings.lg, Spacings.xxl, Spacings.lg, Spacings.sm,
              ),
              child: Text(
                'Class Breakdown',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),

          // ─── Class Cards ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final classData = state.attendanceReport[index];
                  final classId = classData['classId'] as String? ?? '';
                  final isExpanded = _expandedClassId == classId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: _ClassBreakdownCard(
                      classData: classData,
                      isExpanded: isExpanded,
                      onToggle: () {
                        setState(() {
                          _expandedClassId = isExpanded ? null : classId;
                        });
                      },
                    ),
                  );
                },
                childCount: state.attendanceReport.length,
              ),
            ),
          ),

          // ─── Export Button ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: AppButton(
                label: 'Export Report',
                onPressed: _isExporting ? null : _exportReport,
                variant: AppButtonVariant.outlined,
                fullWidth: true,
                icon: Icons.download_rounded,
                isLoading: _isExporting,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Statistics ────────────────────────────────────────────

  Widget _buildSummaryStats(BuildContext context, ReportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    // Compute aggregates from report data
    double totalPresent = 0;
    double totalAbsent = 0;
    double totalLate = 0;
    int classCount = state.attendanceReport.length;

    for (final classData in state.attendanceReport) {
      totalPresent += (classData['presentPercent'] as num?)?.toDouble() ?? 0;
      totalAbsent += (classData['absentPercent'] as num?)?.toDouble() ?? 0;
      totalLate += (classData['latePercent'] as num?)?.toDouble() ?? 0;
    }

    final avgPresent = classCount > 0 ? totalPresent / classCount : 0;
    final avgAbsent = classCount > 0 ? totalAbsent / classCount : 0;
    final avgLate = classCount > 0 ? totalLate / classCount : 0;

    return Padding(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Date range display ───────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        _formatDate(_startDate),
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Text('to', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: Spacings.sm),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.sm,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        _formatDate(_endDate),
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),

          // ─── Stats cards ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Present',
                  value: '${avgPresent.toStringAsFixed(1)}%',
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: _StatCard(
                  label: 'Absent',
                  value: '${avgAbsent.toStringAsFixed(1)}%',
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: _StatCard(
                  label: 'Late',
                  value: '${avgLate.toStringAsFixed(1)}%',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Export ────────────────────────────────────────────────────────

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance report exported (placeholder).')),
      );
    }
  }

  // ─── Filter Sheet ──────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, List<ClassEntity> classes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                'Filter Attendance Report',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              // Class filter
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
              const SizedBox(height: Spacings.md),
              // Term filter
              DropdownButtonFormField<String>(
                value: _selectedTermId,
                decoration: const InputDecoration(
                  labelText: 'Term',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: const [
                  DropdownMenuItem<String>(value: null, child: Text('Current Term')),
                  DropdownMenuItem<String>(value: 'first_term', child: Text('First Term')),
                  DropdownMenuItem<String>(value: 'second_term', child: Text('Second Term')),
                  DropdownMenuItem<String>(value: 'third_term', child: Text('Third Term')),
                ],
                onChanged: (value) {
                  setState(() => _selectedTermId = value);
                  setModalState(() => _selectedTermId = value);
                },
              ),
              const SizedBox(height: Spacings.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedClassId = null;
                          _selectedTermId = null;
                          _startDate = null;
                          _endDate = null;
                        });
                        setModalState(() {
                          _selectedClassId = null;
                          _selectedTermId = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: Spacings.md),
                  Expanded(
                    child: AppButton(
                      label: 'Apply',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _refreshReport();
                      },
                      variant: AppButtonVariant.elevated,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + Spacings.md),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return AppCard(
      padding: const EdgeInsets.all(Spacings.md),
      child: Column(
        children: [
          Text(
            value,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassBreakdownCard extends StatelessWidget {
  const _ClassBreakdownCard({
    required this.classData,
    required this.isExpanded,
    required this.onToggle,
  });

  final Map<String, dynamic> classData;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final className = classData['className'] as String? ?? 'Unknown';
    final totalStudents = classData['totalStudents'] as int? ?? 0;
    final presentPct = (classData['presentPercent'] as num?)?.toDouble() ?? 0;
    final absentPct = (classData['absentPercent'] as num?)?.toDouble() ?? 0;
    final latePct = (classData['latePercent'] as num?)?.toDouble() ?? 0;
    final students = classData['students'] as List<Map<String, dynamic>>? ?? [];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Class header row ──────────────────────────────────────
          GestureDetector(
            onTap: onToggle,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.sm),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Icon(Icons.class_rounded, size: Spacings.mdIcon, color: cs.primary),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '$totalStudents students',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                // ─── Percentage bars ─────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniBar(label: 'Present', pct: presentPct, color: AppColors.success),
                    const SizedBox(height: Spacings.xs),
                    _MiniBar(label: 'Absent', pct: absentPct, color: AppColors.error),
                    const SizedBox(height: Spacings.xs),
                    _MiniBar(label: 'Late', pct: latePct, color: AppColors.warning),
                  ],
                ),
                const SizedBox(width: Spacings.sm),
                Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // ─── Expanded: student detail ──────────────────────────────
          if (isExpanded && students.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            const Divider(height: 1),
            const SizedBox(height: Spacings.md),
            Text(
              'Student Details',
              style: tt.labelMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            ...students.map((student) {
              final name = student['name'] as String? ?? '—';
              final rate = (student['attendanceRate'] as num?)?.toDouble() ?? 0;
              final isHigh = rate >= 95;
              final isLow = rate < 75;

              return Padding(
                padding: const EdgeInsets.only(bottom: Spacings.sm),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: Spacings.smIcon,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacings.sm),
                    Expanded(
                      child: Text(
                        name,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface),
                      ),
                    ),
                    // Attendance rate with indicator
                    if (isHigh)
                      Icon(Icons.arrow_upward_rounded, size: Spacings.smIcon, color: AppColors.success),
                    if (isLow)
                      Icon(Icons.arrow_downward_rounded, size: Spacings.smIcon, color: AppColors.error),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '${rate.toStringAsFixed(1)}%',
                      style: tt.bodySmall?.copyWith(
                        color: isHigh
                            ? AppColors.success
                            : isLow
                                ? AppColors.error
                                : cs.onSurfaceVariant,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.label,
    required this.pct,
    required this.color,
  });

  final String label;
  final double pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: context.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(Spacings.fullRadius),
          ),
        ),
        const SizedBox(width: Spacings.xs),
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
      ],
    );
  }
}
