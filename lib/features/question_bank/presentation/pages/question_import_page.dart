import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/usecases/import_questions_usecase.dart';
import '../providers/import_export_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION IMPORT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Import page for bulk uploading questions from CSV, Excel, JSON, or
/// DOCX files with format selection, mapping configuration, preview,
/// and import progress tracking.
class QuestionImportPage extends ConsumerStatefulWidget {
  const QuestionImportPage({super.key});

  @override
  ConsumerState<QuestionImportPage> createState() =>
      _QuestionImportPageState();
}

class _QuestionImportPageState extends ConsumerState<QuestionImportPage> {
  // ─── State ──────────────────────────────────────────────────────────

  String _selectedFormat = 'csv';
  String? _selectedFileName;
  bool _isDragging = false;
  bool _autoPublish = false;
  DifficultyLevel _defaultDifficulty = DifficultyLevel.medium;
  ExamType _defaultExamType = ExamType.practice;
  String? _selectedSubject;
  String? _selectedClass;
  String? _selectedTopic;

  // Preview data (simulated parsed rows)
  List<Map<String, String>> _previewRows = [];
  bool _showPreview = false;

  // Expandable error list
  final Set<int> _expandedErrors = {};

  static const _importFormats = [
    _ImportFormat('csv', 'CSV', Icons.table_chart_rounded, 'Comma-separated values'),
    _ImportFormat('excel', 'Excel', Icons.table_view_rounded, 'XLSX spreadsheet'),
    _ImportFormat('json', 'JSON', Icons.data_object_rounded, 'Structured JSON data'),
    _ImportFormat('word', 'DOCX', Icons.description_rounded, 'Word document'),
  ];

  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void dispose() {
    super.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importExportProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Import Questions',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── File Upload Area ────────────────────────────────────
            _buildFileUploadArea(context),
            const SizedBox(height: Spacings.xl),

            // ── Format Selection ────────────────────────────────────
            _buildSectionTitle(context, 'Import Format'),
            const SizedBox(height: Spacings.md),
            _buildFormatSelection(context),
            const SizedBox(height: Spacings.xl),

            // ── Template Download ───────────────────────────────────
            _buildTemplateDownload(context),
            const SizedBox(height: Spacings.xl),

            // ── Mapping Configuration ───────────────────────────────
            _buildMappingConfiguration(context),
            const SizedBox(height: Spacings.xl),

            // ── Import Options ──────────────────────────────────────
            _buildImportOptions(context),
            const SizedBox(height: Spacings.xl),

            // ── Preview Table ───────────────────────────────────────
            if (_showPreview) ...[
              _buildSectionTitle(context, 'Preview (First 5 Rows)'),
              const SizedBox(height: Spacings.md),
              _buildPreviewTable(context),
              const SizedBox(height: Spacings.xl),
            ],

            // ── Import Progress / Result / Error ────────────────────
            if (state.isImporting)
              _buildImportProgress(context, state)
            else if (state.isImportComplete)
              _buildImportResult(context, state)
            else if (state.isImportFailed)
              _buildImportFailed(context, state)
            else
              _buildStartImportButton(context, state),

            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }

  // ─── Section Title ──────────────────────────────────────────────────

  Widget _buildSectionTitle(BuildContext context, String title) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.sm,
            vertical: Spacings.xs,
          ),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
          child: Text(
            title,
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ─── File Upload Area ───────────────────────────────────────────────

  Widget _buildFileUploadArea(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final borderColor = _isDragging
        ? cs.primary
        : cs.outlineVariant.withValues(alpha: 0.6);
    final bgColor = _isDragging
        ? cs.primary.withValues(alpha: isDark ? 0.15 : 0.06)
        : cs.surfaceContainerLow;

    return GestureDetector(
      onTap: _pickFile,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isDragging = true),
        onExit: (_) => setState(() => _isDragging = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacings.xl,
            vertical: Spacings.xxl,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(Spacings.lgRadius),
            border: Border.all(
              color: borderColor,
              width: _isDragging ? 2.0 : 1.5,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.lg),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedFileName != null
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_outlined,
                  size: Spacings.xlIcon,
                  color: _selectedFileName != null
                      ? AppColors.successOf(cs.brightness)
                      : cs.primary,
                ),
              ),
              const SizedBox(height: Spacings.lg),
              Text(
                _selectedFileName != null
                    ? _selectedFileName!
                    : 'Drag & drop or click to upload',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                _selectedFileName != null
                    ? 'Click to change file'
                    : 'Supports CSV, Excel, JSON, and DOCX files',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(height: Spacings.md),
                AppButton(
                  label: 'Remove File',
                  onPressed: () {
                    setState(() {
                      _selectedFileName = null;
                      _showPreview = false;
                      _previewRows = [];
                    });
                  },
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  icon: Icons.close_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Format Selection ───────────────────────────────────────────────

  Widget _buildFormatSelection(BuildContext context) {
    return SegmentedButton<String>(
      segments: _importFormats
          .map((f) => ButtonSegment(
                value: f.value,
                label: Text(f.label),
                icon: Icon(f.icon, size: Spacings.smIcon),
              ),)
          .toList(),
      selected: {_selectedFormat},
      onSelectionChanged: (selected) {
        setState(() => _selectedFormat = selected.first);
      },
    );
  }

  // ─── Template Download ──────────────────────────────────────────────

  Widget _buildTemplateDownload(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Download Templates',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Download a template file to ensure your data matches the expected format.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: _importFormats.map((fmt) {
              return ActionChip(
                avatar: Icon(fmt.icon, size: Spacings.smIcon),
                label: Text(fmt.label),
                onPressed: () => _downloadTemplate(fmt.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Mapping Configuration ──────────────────────────────────────────

  Widget _buildMappingConfiguration(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Mapping Configuration',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Assign imported questions to a subject, class, and topic.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Spacings.lg),
          AppDropdownField<String>(
            label: 'Subject',
            hint: 'Select subject',
            prefixIcon: Icons.book_outlined,
            items: const [
              'Mathematics',
              'English',
              'Physics',
              'Chemistry',
              'Biology',
              'History',
              'Geography',
            ],
            selectedItem: _selectedSubject,
            onChanged: (v) => setState(() => _selectedSubject = v),
            itemLabel: (s) => s,
          ),
          const SizedBox(height: Spacings.md),
          AppDropdownField<String>(
            label: 'Class',
            hint: 'Select class',
            prefixIcon: Icons.school_outlined,
            items: const [
              'JSS 1',
              'JSS 2',
              'JSS 3',
              'SSS 1',
              'SSS 2',
              'SSS 3',
            ],
            selectedItem: _selectedClass,
            onChanged: (v) => setState(() => _selectedClass = v),
            itemLabel: (c) => c,
          ),
          const SizedBox(height: Spacings.md),
          AppDropdownField<String>(
            label: 'Topic',
            hint: 'Select topic',
            prefixIcon: Icons.topic_outlined,
            items: const [
              'Algebra',
              'Geometry',
              'Trigonometry',
              'Calculus',
              'Statistics',
            ],
            selectedItem: _selectedTopic,
            onChanged: (v) => setState(() => _selectedTopic = v),
            itemLabel: (t) => t,
          ),
        ],
      ),
    );
  }

  // ─── Import Options ─────────────────────────────────────────────────

  Widget _buildImportOptions(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Import Options',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.lg),
          AppDropdownField<DifficultyLevel>(
            label: 'Default Difficulty',
            prefixIcon: Icons.signal_cellular_alt_rounded,
            items: DifficultyLevel.values,
            selectedItem: _defaultDifficulty,
            onChanged: (v) {
              if (v != null) setState(() => _defaultDifficulty = v);
            },
            itemLabel: (d) => d.label,
          ),
          const SizedBox(height: Spacings.md),
          AppDropdownField<ExamType>(
            label: 'Default Exam Type',
            prefixIcon: Icons.quiz_outlined,
            items: ExamType.values,
            selectedItem: _defaultExamType,
            onChanged: (v) {
              if (v != null) setState(() => _defaultExamType = v);
            },
            itemLabel: (e) => e.label,
          ),
          const SizedBox(height: Spacings.md),
          SwitchListTile(
            title: Text(
              'Auto-publish imported questions',
              style: tt.bodyMedium?.copyWith(
                fontWeight: AppTypography.wMedium,
                color: cs.onSurface,
              ),
            ),
            subtitle: Text(
              'When enabled, all imported questions will be published immediately.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            value: _autoPublish,
            onChanged: (v) => setState(() => _autoPublish = v),
            contentPadding: EdgeInsets.zero,
            dense: true,
            secondary: Icon(
              _autoPublish
                  ? Icons.publish_rounded
                  : Icons.publish_outlined,
              color: _autoPublish ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Preview Table ──────────────────────────────────────────────────

  Widget _buildPreviewTable(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    if (_previewRows.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(Spacings.lg),
        child: AppEmptyState.noData(
          title: 'No Preview Available',
          subtitle: 'Upload a file to see a preview of parsed data.',
        ),
      );
    }

    final columns = _previewRows.first.keys.toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            cs.primary.withValues(alpha: isDark ? 0.15 : 0.06),
          ),
          columns: columns
              .map((col) => DataColumn(
                    label: Text(
                      col,
                      style: tt.labelSmall?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.primary,
                      ),
                    ),
                  ),)
              .toList(),
          rows: _previewRows.take(5).map((row) {
            return DataRow(
              cells: columns
                  .map((col) => DataCell(
                        Text(
                          row[col] ?? '',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),)
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Start Import Button ────────────────────────────────────────────

  Widget _buildStartImportButton(BuildContext context, ImportExportState state) {
    final canImport = _selectedFileName != null;

    return Column(
      children: [
        if (state.error != null) ...[
          AppErrorState.genericError(
            message: state.error,
            onRetry: _startImport,
          ),
          const SizedBox(height: Spacings.lg),
        ],
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Start Import',
            onPressed: canImport ? _startImport : null,
            variant: AppButtonVariant.elevated,
            fullWidth: true,
            icon: Icons.file_upload_rounded,
            isDisabled: !canImport,
          ),
        ),
      ],
    );
  }

  // ─── Import Progress ────────────────────────────────────────────────

  Widget _buildImportProgress(BuildContext context, ImportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final importStatus = state.importStatus;
    final imported = importStatus?.importedCount ?? 0;
    final failed = importStatus?.failedCount ?? 0;
    final total = importStatus?.totalQuestions ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.xl),
      child: Column(
        children: [
          const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
          const SizedBox(height: Spacings.lg),
          Text(
            'Importing Questions…',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: state.importProgress,
              minHeight: 8.0,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            '${(state.importProgress * 100).toInt()}% complete',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: Spacings.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressStat(
                context,
                icon: Icons.check_circle_outline_rounded,
                value: '$imported',
                label: 'Imported',
                color: AppColors.successOf(cs.brightness),
              ),
              _buildProgressStat(
                context,
                icon: Icons.error_outline_rounded,
                value: '$failed',
                label: 'Failed',
                color: AppColors.errorOf(cs.brightness),
              ),
              _buildProgressStat(
                context,
                icon: Icons.inventory_2_outlined,
                value: '$total',
                label: 'Total',
                color: cs.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final tt = context.textTheme;

    return Column(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: color),
        const SizedBox(height: Spacings.xs),
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ─── Import Result ──────────────────────────────────────────────────

  Widget _buildImportResult(BuildContext context, ImportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final importStatus = state.importStatus;
    final imported = importStatus?.importedCount ?? 0;
    final failed = importStatus?.failedCount ?? 0;
    final total = importStatus?.totalQuestions ?? 0;
    final errors = importStatus?.errors ?? [];

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: AppColors.successOf(cs.brightness)
                  .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: Spacings.xlIcon,
              color: AppColors.successOf(cs.brightness),
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Text(
            'Import Complete!',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),

          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultChip(
                context,
                label: 'Imported',
                value: '$imported',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.successOf(cs.brightness),
              ),
              _buildResultChip(
                context,
                label: 'Failed',
                value: '$failed',
                icon: Icons.error_outline_rounded,
                color: AppColors.errorOf(cs.brightness),
              ),
              _buildResultChip(
                context,
                label: 'Total',
                value: '$total',
                icon: Icons.inventory_2_outlined,
                color: cs.primary,
              ),
            ],
          ),

          // Error details
          if (errors.isNotEmpty) ...[
            const SizedBox(height: Spacings.xl),
            _buildSectionTitle(context, 'Error Details'),
            const SizedBox(height: Spacings.md),
            _buildErrorList(context, errors),
          ],

          const SizedBox(height: Spacings.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Import Another',
                  onPressed: _resetImport,
                  variant: AppButtonVariant.outlined,
                  fullWidth: true,
                  icon: Icons.file_upload_outlined,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: AppButton(
                  label: 'View Imported Questions',
                  onPressed: () => context.go(RouteNames.questionBankList),
                  variant: AppButtonVariant.elevated,
                  fullWidth: true,
                  icon: Icons.visibility_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final tt = context.textTheme;

    return Column(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: color),
        const SizedBox(height: Spacings.xs),
        Text(
          value,
          style: tt.headlineSmall?.copyWith(
            fontWeight: AppTypography.wBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ─── Error Details List ─────────────────────────────────────────────

  Widget _buildErrorList(
    BuildContext context,
    List<Map<String, dynamic>> errors,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      children: errors.asMap().entries.map((entry) {
        final index = entry.key;
        final error = entry.value;
        final isExpanded = _expandedErrors.contains(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: ExpansionPanelList(
              expansionCallback: (_, isExpanded) {
                setState(() {
                  if (isExpanded) {
                    _expandedErrors.add(index);
                  } else {
                    _expandedErrors.remove(index);
                  }
                });
              },
              children: [
                ExpansionPanel(
                  isExpanded: isExpanded,
                  headerBuilder: (ctx, isExpanded) {
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.error_outline_rounded,
                        size: Spacings.mdIcon,
                        color: AppColors.errorOf(cs.brightness),
                      ),
                      title: Text(
                        'Row ${error['row'] ?? index + 1}',
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wMedium,
                          color: cs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${error['error'] ?? 'Unknown error'}',
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.errorOf(cs.brightness),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacings.lg,
                      0,
                      Spacings.lg,
                      Spacings.lg,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Spacings.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        '${error['details'] ?? error['error'] ?? 'No additional details'}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Import Failed ──────────────────────────────────────────────────

  Widget _buildImportFailed(BuildContext context, ImportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: AppColors.errorOf(cs.brightness)
                  .withValues(alpha: context.isDarkMode ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: Spacings.xlIcon,
              color: AppColors.errorOf(cs.brightness),
            ),
          ),
          const SizedBox(height: Spacings.lg),
          Text(
            'Import Failed',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            state.error ?? 'An unexpected error occurred during import.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.xl),
          AppButton(
            label: 'Try Again',
            onPressed: _startImport,
            variant: AppButtonVariant.elevated,
            fullWidth: true,
            icon: Icons.refresh_rounded,
          ),
          const SizedBox(height: Spacings.md),
          AppButton(
            label: 'Import Another',
            onPressed: _resetImport,
            variant: AppButtonVariant.outlined,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  void _pickFile() {
    // Simulate file picking
    setState(() {
      _selectedFileName = 'questions_import.$_selectedFormat';
      _showPreview = true;
      _previewRows = _generatePreviewData();
    });
  }

  List<Map<String, String>> _generatePreviewData() {
    return List.generate(5, (i) => {
          'Question': 'Sample question ${i + 1}',
          'Type': 'multiple_choice',
          'Answer': 'Option A',
          'Difficulty': 'medium',
          'Marks': '2',
        },);
  }

  void _startImport() {
    ref.read(importExportProvider.notifier).startImport(
          ImportQuestionsParams(
            importJob: QuestionImportEntity(
              id: '',
              schoolId: 'school_001',
              createdBy: 'current_user',
              source: _selectedFormat,
              fileName: _selectedFileName,
              totalQuestions: 0,
              createdAt: DateTime.now(),
            ),
          ),
        );
  }

  void _resetImport() {
    ref.read(importExportProvider.notifier).resetState();
    setState(() {
      _selectedFileName = null;
      _showPreview = false;
      _previewRows = [];
      _expandedErrors.clear();
    });
  }

  void _downloadTemplate(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $format template…'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _ImportFormat {
  const _ImportFormat(
    this.value,
    this.label,
    this.icon,
    this.description,
  );

  final String value;
  final String label;
  final IconData icon;
  final String description;
}
