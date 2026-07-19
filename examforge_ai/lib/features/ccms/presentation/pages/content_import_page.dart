import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class ContentImportPage extends ConsumerStatefulWidget {
  const ContentImportPage({super.key});

  @override
  ConsumerState<ContentImportPage> createState() =>
      _ContentImportPageState();
}

class _ContentImportPageState extends ConsumerState<ContentImportPage> {
  bool _licensingDeclared = false;
  String? _selectedFormat;
  final Map<String, String> _fieldMappings = {};
  bool _isImporting = false;

  static const _supportedFormats = ['CSV', 'Excel (.xlsx)', 'JSON'];
  static const _contentFields = [
    'title',
    'body',
    'content_type',
    'subject',
    'level',
    'topic',
    'difficulty',
    'bloom_level',
    'explanation',
    'marking_scheme',
    'teacher_notes',
    'marks_allocated',
    'time_allocated',
    'tags',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentImportProvider.notifier).loadImports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentImportProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Content Import'),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── File Upload Area ───────────────────────────────────
            Text('Upload File',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.md),
            GestureDetector(
              onTap: () => _showFilePicker(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: Spacings.xxxl, horizontal: Spacings.xl),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: cs.outline, style: BorderStyle.solid),
                  borderRadius: Spacings.borderRadiusMd,
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_rounded,
                        size: 48, color: cs.primary),
                    const SizedBox(height: Spacings.md),
                    Text('Drag & drop or tap to upload',
                        style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant)),
                    const SizedBox(height: Spacings.xs),
                    Text('Supported: CSV, Excel, JSON',
                        style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Spacings.sectionGap,

            // ── Supported Formats Info ─────────────────────────────
            Text('Supported Formats',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            AppCard(
              child: Column(
                children: _supportedFormats
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: Spacings.xs),
                          child: Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: Spacings.smIcon, color: cs.primary),
                              const SizedBox(width: Spacings.sm),
                              Text(f, style: tt.bodyMedium),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            Spacings.sectionGap,

            // ── Mapping Configuration ──────────────────────────────
            Text('Field Mapping Configuration',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                  labelText: 'File Format', border: OutlineInputBorder()),
              items: _supportedFormats
                  .map((f) =>
                      DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFormat = v),
            ),
            const SizedBox(height: Spacings.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Map your file columns to CCMS content fields. '
                      'Unmapped fields will be left empty.',
                      style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: Spacings.md),
                  ..._contentFields.map((field) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: Spacings.sm),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(field,
                                  style: tt.bodySmall?.copyWith(
                                      fontWeight: AppTypography.wMedium,
                                      color: cs.onSurface)),
                            ),
                            const SizedBox(width: Spacings.sm),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Column name in file',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: Spacings.md,
                                          vertical: Spacings.sm),
                                ),
                                onChanged: (v) {
                                  _fieldMappings[field] = v;
                                },
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Spacings.sectionGap,

            // ── Licensing Declaration ──────────────────────────────
            Container(
              padding: Spacings.paddingCard,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: Spacings.borderRadiusMd,
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _licensingDeclared,
                    onChanged: (v) =>
                        setState(() => _licensingDeclared = v ?? false),
                    activeColor: cs.primary,
                  ),
                  Expanded(
                    child: Text(
                      'I confirm that I have the right to import and use this content. '
                      'All imported content will be reviewed before publishing.',
                      style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            Spacings.sectionGap,

            // ── Start Import Button ───────────────────────────────
            AppButton(
              label: 'Start Import',
              onPressed: _licensingDeclared ? _startImport : null,
              fullWidth: true,
              icon: Icons.upload_file_rounded,
              isLoading: _isImporting,
            ),
            Spacings.sectionGap,

            // ── Import Progress ───────────────────────────────────
            if (_isImporting) ...[
              const Center(child: AppLoadingSpinner()),
              const SizedBox(height: Spacings.md),
              AppCard(
                child: Column(
                  children: [
                    Text('Import in progress…',
                        style: tt.bodyMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold)),
                    const SizedBox(height: Spacings.sm),
                    AppLoadingBar(value: null),
                  ],
                ),
              ),
              Spacings.sectionGap,
            ],

            // ── Import History ────────────────────────────────────
            Text('Import History',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.md),
            if (state.isLoading && state.imports.isEmpty)
              const Center(child: AppLoadingSpinner())
            else if (state.imports.isEmpty)
              AppEmptyState.noData(subtitle: 'No import history')
            else
              ...state.imports.map((importEntry) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: AppCard(
                      onTap: () => _showImportDetail(importEntry),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(importEntry.fileName,
                                    style: tt.titleSmall?.copyWith(
                                        fontWeight:
                                            AppTypography.wSemiBold)),
                              ),
                              _importStatusBadge(importEntry.status, cs),
                            ],
                          ),
                          const SizedBox(height: Spacings.sm),
                          ImportProgressIndicator(
                              importEntry: importEntry),
                          if (importEntry.errorCount > 0) ...[
                            const SizedBox(height: Spacings.sm),
                            Text(
                              '${importEntry.errorCount} errors · Tap to view details',
                              style: tt.bodySmall?.copyWith(
                                  color: AppColors.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _importStatusBadge(ImportStatus status, ColorScheme cs) {
    final color = switch (status) {
      ImportStatus.pending => AppColors.warning,
      ImportStatus.processing => AppColors.info,
      ImportStatus.completed => AppColors.success,
      ImportStatus.failed => AppColors.error,
      ImportStatus.partiallyCompleted => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacings.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: Spacings.borderRadiusSm,
      ),
      child: Text(status.label,
          style: AppTypography.labelSmall.copyWith(
              color: color, fontWeight: AppTypography.wSemiBold)),
    );
  }

  void _showFilePicker() {
    // In production, use file_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker would open here')),
    );
  }

  void _startImport() {
    setState(() => _isImporting = true);
    // Simulate import process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Import completed. Reviewing content…')),
        );
      }
    });
  }

  void _showImportDetail(ContentImportEntry importEntry) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: Spacings.paddingScreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(importEntry.fileName,
                        style: tt.headlineSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold)),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              ImportProgressIndicator(importEntry: importEntry),
              const SizedBox(height: Spacings.lg),
              Text('Summary',
                  style: tt.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold)),
              const SizedBox(height: Spacings.sm),
              Row(
                children: [
                  StatOverviewCard(
                    title: 'Total',
                    value: '${importEntry.totalItems}',
                    icon: Icons.list_rounded,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: Spacings.md),
                  StatOverviewCard(
                    title: 'Imported',
                    value: '${importEntry.successCount}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: Spacings.md),
                  StatOverviewCard(
                    title: 'Errors',
                    value: '${importEntry.errorCount}',
                    icon: Icons.error_rounded,
                    color: AppColors.error,
                  ),
                ],
              ),
              if (importEntry.errorCount > 0) ...[
                const SizedBox(height: Spacings.lg),
                Text('Error Log',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: AppColors.error)),
                const SizedBox(height: Spacings.sm),
                AppCard(
                  child: Text(
                    'Import errors will be displayed here. '
                    'Row numbers and error messages for each failed item.',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
