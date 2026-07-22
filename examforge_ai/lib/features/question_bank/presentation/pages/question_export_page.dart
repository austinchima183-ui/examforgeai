import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../domain/entities/question_entities.dart';
import '../../domain/usecases/export_questions_usecase.dart';
import '../providers/import_export_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// QUESTION EXPORT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Export page for downloading questions in PDF, DOCX, Excel, CSV, or
/// JSON format with filter options, include toggles, and layout selection.
class QuestionExportPage extends ConsumerStatefulWidget {
  const QuestionExportPage({super.key, this.selectedQuestionIds});

  /// Optional list of specific question IDs to export.
  final List<String>? selectedQuestionIds;

  @override
  ConsumerState<QuestionExportPage> createState() =>
      _QuestionExportPageState();
}

class _QuestionExportPageState extends ConsumerState<QuestionExportPage> {
  // ─── State ──────────────────────────────────────────────────────────

  String _selectedFormat = 'excel';
  _ExportScope _exportScope = _ExportScope.all;
  DifficultyLevel? _filterDifficulty;
  QuestionType? _filterQuestionType;
  String? _filterSubject;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _selectedCollectionId;

  bool _includeAnswers = true;
  bool _includeExplanations = false;
  bool _includeTeacherNotes = false;
  bool _includeAttachmentsMetadata = false;
  bool _includeTags = true;

  _ExportLayout _exportLayout = _ExportLayout.compact;

  static const _formats = [
    _ExportFormat('pdf', 'PDF', Icons.picture_as_pdf_rounded,
        'Printable document format', Color(0xFFDC2626)),
    _ExportFormat('docx', 'DOCX', Icons.description_rounded,
        'Word document format', Color(0xFF2563EB)),
    _ExportFormat('excel', 'Excel', Icons.table_view_rounded,
        'XLSX spreadsheet', Color(0xFF16A34A)),
    _ExportFormat('csv', 'CSV', Icons.table_chart_rounded,
        'Comma-separated values', Color(0xFFD97706)),
    _ExportFormat('json', 'JSON', Icons.data_object_rounded,
        'Structured data format', Color(0xFF7C3AED)),
  ];

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importExportProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Export Questions',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Export Format Selection ─────────────────────────────
            _buildSectionTitle(context, 'Export Format'),
            const SizedBox(height: Spacings.md),
            _buildFormatSelection(context),
            const SizedBox(height: Spacings.xl),

            // ── Filter Section ──────────────────────────────────────
            _buildSectionTitle(context, 'What to Export'),
            const SizedBox(height: Spacings.md),
            _buildFilterSection(context),
            const SizedBox(height: Spacings.xl),

            // ── Include Options ─────────────────────────────────────
            _buildSectionTitle(context, 'Include Options'),
            const SizedBox(height: Spacings.md),
            _buildIncludeOptions(context),
            const SizedBox(height: Spacings.xl),

            // ── Export Layout Options ───────────────────────────────
            _buildSectionTitle(context, 'Export Layout'),
            const SizedBox(height: Spacings.md),
            _buildLayoutOptions(context),
            const SizedBox(height: Spacings.xl),

            // ── Progress / Result / Error ───────────────────────────
            if (state.isExporting)
              _buildExportProgress(context, state)
            else if (state.isExportComplete)
              _buildExportComplete(context, state)
            else if (state.isExportFailed)
              _buildExportFailed(context, state)
            else
              _buildExportButton(context, state),

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
            color: cs.primary.withOpacity(context.isDarkMode ? 0.2 : 0.1),
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

  // ─── Format Selection ───────────────────────────────────────────────

  Widget _buildFormatSelection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      children: _formats.map((fmt) {
        final isSelected = _selectedFormat == fmt.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.sm),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFormat = fmt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(Spacings.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? fmt.color.withOpacity(isDark ? 0.15 : 0.06)
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                border: Border.all(
                  color: isSelected
                      ? fmt.color
                      : cs.outlineVariant.withOpacity(0.5),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacings.md),
                    decoration: BoxDecoration(
                      color: fmt.color.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(Spacings.mdRadius),
                    ),
                    child: Icon(fmt.icon, size: Spacings.lgIcon, color: fmt.color),
                  ),
                  const SizedBox(width: Spacings.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fmt.label,
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? AppTypography.wSemiBold
                                : AppTypography.wMedium,
                            color: isSelected ? fmt.color : cs.onSurface,
                          ),
                        ),
                        Text(
                          fmt.description,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: fmt.color, size: Spacings.mdIcon),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Filter Section ─────────────────────────────────────────────────

  Widget _buildFilterSection(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // If specific questions are selected, show scope info
    if (widget.selectedQuestionIds != null &&
        widget.selectedQuestionIds!.isNotEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: AppColors.info
                    .withOpacity(context.isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: Spacings.lgIcon,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: Spacings.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Questions',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '${widget.selectedQuestionIds!.length} question${widget.selectedQuestionIds!.length == 1 ? '' : 's'} selected for export',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scope selection
          Text(
            'Export Scope',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: _ExportScope.values.map((scope) {
              final isSelected = _exportScope == scope;
              return ChoiceChip(
                label: Text(_scopeLabel(scope)),
                selected: isSelected,
                onSelected: (_) => setState(() => _exportScope = scope),
                avatar: Icon(_scopeIcon(scope), size: Spacings.smIcon),
              );
            }).toList(),
          ),
          const SizedBox(height: Spacings.lg),

          // Conditional filters based on scope
          if (_exportScope == _ExportScope.filtered ||
              _exportScope == _ExportScope.all) ...[
            Row(
              children: [
                Expanded(
                  child: AppDropdownField<String>(
                    label: 'Subject',
                    hint: 'All subjects',
                    prefixIcon: Icons.book_outlined,
                    items: const [
                      'Mathematics',
                      'English',
                      'Physics',
                      'Chemistry',
                      'Biology',
                    ],
                    selectedItem: _filterSubject,
                    onChanged: (v) => setState(() => _filterSubject = v),
                    itemLabel: (s) => s,
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: AppDropdownField<DifficultyLevel>(
                    label: 'Difficulty',
                    hint: 'All levels',
                    prefixIcon: Icons.signal_cellular_alt_rounded,
                    items: DifficultyLevel.values,
                    selectedItem: _filterDifficulty,
                    onChanged: (v) =>
                        setState(() => _filterDifficulty = v),
                    itemLabel: (d) => d.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.md),
            AppDropdownField<QuestionType>(
              label: 'Question Type',
              hint: 'All types',
              prefixIcon: Icons.category_outlined,
              items: QuestionType.values,
              selectedItem: _filterQuestionType,
              onChanged: (v) =>
                  setState(() => _filterQuestionType = v),
              itemLabel: (t) => t.label,
            ),
            const SizedBox(height: Spacings.md),
          ],

          if (_exportScope == _ExportScope.collection) ...[
            AppDropdownField<String>(
              label: 'Collection',
              hint: 'Select a collection',
              prefixIcon: Icons.collections_bookmark_outlined,
              items: const [
                'Biology Chapter 5',
                'Math Midterm Prep',
                'Physics Formulas',
              ],
              selectedItem: _selectedCollectionId,
              onChanged: (v) =>
                  setState(() => _selectedCollectionId = v),
              itemLabel: (c) => c,
            ),
            const SizedBox(height: Spacings.md),
          ],

          // Date range
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context: context,
                  label: 'From Date',
                  value: _dateFrom,
                  onSelected: (d) => setState(() => _dateFrom = d),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: _buildDateField(
                  context: context,
                  label: 'To Date',
                  value: _dateTo,
                  onSelected: (d) => setState(() => _dateTo = d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onSelected,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final displayText =
        value != null ? '${months[value.month]} ${value.day}, ${value.year}' : null;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Spacings.lgRadius),
                ),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onSelected(picked);
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: displayText != null
              ? TextEditingController(text: displayText)
              : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Select date',
            prefixIcon: Icon(Icons.calendar_today_outlined, size: Spacings.mdIcon),
            suffixIcon: Icon(Icons.arrow_drop_down_rounded,
                color: cs.onSurfaceVariant),
          ),
          readOnly: true,
          enabled: true,
        ),
      ),
    );
  }

  // ─── Include Options ────────────────────────────────────────────────

  Widget _buildIncludeOptions(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final options = [
      _IncludeOption(
        label: 'Include Answers',
        subtitle: 'Correct answers and answer options',
        icon: Icons.check_circle_outline_rounded,
        value: _includeAnswers,
        onChanged: (v) => setState(() => _includeAnswers = v),
      ),
      _IncludeOption(
        label: 'Include Explanations',
        subtitle: 'Answer explanations and reasoning',
        icon: Icons.lightbulb_outline_rounded,
        value: _includeExplanations,
        onChanged: (v) => setState(() => _includeExplanations = v),
      ),
      _IncludeOption(
        label: 'Include Teacher Notes',
        subtitle: 'Private teacher notes and references',
        icon: Icons.sticky_note_2_outlined,
        value: _includeTeacherNotes,
        onChanged: (v) => setState(() => _includeTeacherNotes = v),
      ),
      _IncludeOption(
        label: 'Include Attachments Metadata',
        subtitle: 'File names, types, and sizes (not the actual files)',
        icon: Icons.attach_file_rounded,
        value: _includeAttachmentsMetadata,
        onChanged: (v) => setState(() => _includeAttachmentsMetadata = v),
      ),
      _IncludeOption(
        label: 'Include Tags',
        subtitle: 'Question tags and categories',
        icon: Icons.label_outline_rounded,
        value: _includeTags,
        onChanged: (v) => setState(() => _includeTags = v),
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        children: options.map((opt) {
          return SwitchListTile(
            title: Row(
              children: [
                Icon(opt.icon, size: Spacings.mdIcon, color: cs.primary),
                const SizedBox(width: Spacings.sm),
                Text(
                  opt.label,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wMedium,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              opt.subtitle,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            value: opt.value,
            onChanged: opt.onChanged,
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  // ─── Export Layout Options ──────────────────────────────────────────

  Widget _buildLayoutOptions(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final layouts = [
      _LayoutOption(
        value: _ExportLayout.onePerPage,
        icon: Icons.crop_portrait_rounded,
        label: 'One per page',
        description: 'Each question on its own page',
      ),
      _LayoutOption(
        value: _ExportLayout.compact,
        icon: Icons.view_agenda_rounded,
        label: 'Compact layout',
        description: 'Multiple questions per page',
      ),
      _LayoutOption(
        value: _ExportLayout.examStyle,
        icon: Icons.assignment_rounded,
        label: 'Exam-style layout',
        description: 'Formatted like a real exam paper',
      ),
    ];

    return Row(
      children: layouts.map((layout) {
        final isSelected = _exportLayout == layout.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _exportLayout = layout.value),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: Spacings.xs),
              padding: const EdgeInsets.all(Spacings.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withOpacity(isDark ? 0.15 : 0.06)
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
                border: Border.all(
                  color: isSelected
                      ? cs.primary
                      : cs.outlineVariant.withOpacity(0.5),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    layout.icon,
                    size: Spacings.lgIcon,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    layout.label,
                    style: tt.bodySmall?.copyWith(
                      fontWeight: isSelected
                          ? AppTypography.wSemiBold
                          : AppTypography.wMedium,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    layout.description,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Export Button ──────────────────────────────────────────────────

  Widget _buildExportButton(BuildContext context, ImportExportState state) {
    return Column(
      children: [
        if (state.error != null) ...[
          AppErrorState.genericError(
            message: state.error,
            onRetry: _startExport,
          ),
          const SizedBox(height: Spacings.lg),
        ],
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Start Export',
            onPressed: _startExport,
            variant: AppButtonVariant.elevated,
            fullWidth: true,
            icon: Icons.file_download_rounded,
          ),
        ),
      ],
    );
  }

  // ─── Export Progress ────────────────────────────────────────────────

  Widget _buildExportProgress(BuildContext context, ImportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final exportStatus = state.exportStatus;
    final exported = exportStatus?.exportedCount ?? 0;
    final total = exportStatus?.totalQuestions ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(Spacings.xl),
      child: Column(
        children: [
          const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
          const SizedBox(height: Spacings.lg),
          Text(
            'Exporting Questions…',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.smRadius),
            child: LinearProgressIndicator(
              value: state.exportProgress,
              minHeight: 8.0,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            '${(state.exportProgress * 100).toInt()}% complete • $exported of $total questions',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Export Complete ────────────────────────────────────────────────

  Widget _buildExportComplete(BuildContext context, ImportExportState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final exportStatus = state.exportStatus;
    final exportedCount = exportStatus?.exportedCount ?? 0;
    final fileName = exportStatus?.fileUrl?.split('/').last ??
        'questions_export.$_selectedFormat';

    // Simulate file size based on count
    final fileSize = exportedCount > 0
        ? '${(exportedCount * 2.4).toStringAsFixed(1)} KB'
        : '0 KB';

    return AppCard(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: AppColors.successOf(cs.brightness)
                  .withOpacity(context.isDarkMode ? 0.2 : 0.1),
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
            'Export Complete!',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            '$exportedCount questions exported successfully.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacings.xl),

          // Download section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.file_download_rounded,
                  size: Spacings.xlIcon,
                  color: cs.primary,
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  fileName,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  'File size: $fileSize',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.md),
                AppButton(
                  label: 'Download File',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Download started…'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Spacings.mdRadius),
                        ),
                      ),
                    );
                  },
                  variant: AppButtonVariant.elevated,
                  fullWidth: true,
                  icon: Icons.download_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Export More',
                  onPressed: _resetExport,
                  variant: AppButtonVariant.outlined,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: AppButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                  variant: AppButtonVariant.tonal,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Export Failed ──────────────────────────────────────────────────

  Widget _buildExportFailed(BuildContext context, ImportExportState state) {
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
                  .withOpacity(context.isDarkMode ? 0.2 : 0.1),
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
            'Export Failed',
            style: tt.titleMedium?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            state.error ?? 'An unexpected error occurred during export.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.xl),
          AppButton(
            label: 'Try Again',
            onPressed: _startExport,
            variant: AppButtonVariant.elevated,
            fullWidth: true,
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  void _startExport() {
    QuestionFilterEntity? filter;
    if (_exportScope != _ExportScope.selected ||
        widget.selectedQuestionIds == null) {
      filter = QuestionFilterEntity(
        subjectId: _filterSubject,
        difficulty: _filterDifficulty,
        questionType: _filterQuestionType,
      );
    }

    ref.read(importExportProvider.notifier).startExport(
          ExportQuestionsParams(
            exportJob: QuestionExportEntity(
              id: '',
              schoolId: 'school_001',
              createdBy: 'current_user',
              format: _selectedFormat,
              filter: filter,
              createdAt: DateTime.now(),
            ),
          ),
        );
  }

  void _resetExport() {
    ref.read(importExportProvider.notifier).resetState();
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  String _scopeLabel(_ExportScope scope) {
    switch (scope) {
      case _ExportScope.all:
        return 'All';
      case _ExportScope.filtered:
        return 'Filtered';
      case _ExportScope.selected:
        return 'Selected';
      case _ExportScope.collection:
        return 'Collection';
    }
  }

  IconData _scopeIcon(_ExportScope scope) {
    switch (scope) {
      case _ExportScope.all:
        return Icons.select_all_rounded;
      case _ExportScope.filtered:
        return Icons.filter_list_rounded;
      case _ExportScope.selected:
        return Icons.checklist_rounded;
      case _ExportScope.collection:
        return Icons.collections_bookmark_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER CLASSES & ENUMS
// ═══════════════════════════════════════════════════════════════════════

enum _ExportScope { all, filtered, selected, collection }

enum _ExportLayout { onePerPage, compact, examStyle }

class _ExportFormat {
  const _ExportFormat(
    this.value,
    this.label,
    this.icon,
    this.description,
    this.color,
  );

  final String value;
  final String label;
  final IconData icon;
  final String description;
  final Color color;
}

class _IncludeOption {
  const _IncludeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
}

class _LayoutOption {
  const _LayoutOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.description,
  });

  final _ExportLayout value;
  final IconData icon;
  final String label;
  final String description;
}
