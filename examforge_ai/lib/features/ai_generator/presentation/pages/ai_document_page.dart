import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../widgets/ai_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI DOCUMENT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Document-to-Question page with file upload area, processing status,
/// extracted text preview, identified topics, suggested objectives,
/// generation settings, and generated questions list.
///
/// ```dart
/// AiDocumentPage()
/// ```
class AiDocumentPage extends StatefulWidget {
  const AiDocumentPage({super.key});

  @override
  State<AiDocumentPage> createState() => _AiDocumentPageState();
}

class _AiDocumentPageState extends State<AiDocumentPage> {
  DocumentUploadEntity? _currentDocument;
  bool _isUploading = false;
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  bool _isExtractedTextExpanded = false;
  bool _isGenerating = false;
  final List<GeneratedQuestionEntity> _generatedQuestions = [];

  // Simplified generation settings
  DifficultyLevel _selectedDifficulty = DifficultyLevel.medium;
  int _numQuestions = 5;

  static const _supportedFormats = ['PDF', 'DOCX', 'TXT'];
  static const _maxFileSizeMB = 25;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Document to Questions',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── File Upload Area ────────────────────────────────────
            _buildUploadArea(),
            const SizedBox(height: Spacings.lg),

            // ── Upload Progress ─────────────────────────────────────
            if (_isUploading) _buildUploadProgress(),

            // ── Document Processing Status ──────────────────────────
            if (_currentDocument != null && !_isUploading)
              _buildDocumentProcessingStatus(),

            // ── Extracted Text Preview ──────────────────────────────
            if (_currentDocument?.extractedText != null) ...[
              const SizedBox(height: Spacings.lg),
              _buildExtractedTextPreview(),
            ],

            // ── Identified Topics ──────────────────────────────────
            if (_currentDocument?.identifiedTopics.isNotEmpty == true) ...[
              const SizedBox(height: Spacings.lg),
              _buildIdentifiedTopics(),
            ],

            // ── Suggested Objectives ───────────────────────────────
            if (_currentDocument?.suggestedObjectives.isNotEmpty == true) ...[
              const SizedBox(height: Spacings.lg),
              _buildSuggestedObjectives(),
            ],

            // ── Generation Settings (simplified) ───────────────────
            if (_currentDocument?.status == DocumentStatus.completed) ...[
              Spacings.sectionGap,
              _buildGenerationSettings(),
            ],

            // ── Generate from Document button ──────────────────────
            if (_currentDocument?.status == DocumentStatus.completed &&
                !_isGenerating) ...[
              const SizedBox(height: Spacings.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Generate from Document',
                  onPressed: _handleGenerateFromDocument,
                  variant: AppButtonVariant.elevated,
                  size: AppButtonSize.large,
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            ],

            if (_isGenerating) ...[
              const SizedBox(height: Spacings.lg),
              _buildGeneratingState(),
            ],

            // ── Generated Questions List ───────────────────────────
            if (_generatedQuestions.isNotEmpty) ...[
              Spacings.sectionGap,
              Text(
                'Generated Questions',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.md),
              ..._generatedQuestions.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: Spacings.md),
                    child: GeneratedQuestionCard(question: q),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ── Upload Area ─────────────────────────────────────────────────────

  Widget _buildUploadArea() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: _isUploading ? null : _handleFileUpload,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.xl,
          vertical: Spacings.xxl,
        ),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(Spacings.lgRadius),
          border: Border.all(
            color: cs.primary.withOpacity(0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.lg),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(isDark ? 0.15 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: Spacings.xlIcon,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: Spacings.lg),
            Text(
              'Drag & drop your file here',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'or click to browse',
              style: tt.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            const SizedBox(height: Spacings.md),
            Wrap(
              spacing: Spacings.sm,
              runSpacing: Spacings.sm,
              children: _supportedFormats.map((fmt) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.md,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Text(
                    fmt,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Max file size: ${_maxFileSizeMB}MB',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload Progress ─────────────────────────────────────────────────

  Widget _buildUploadProgress() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppLoadingSpinner(size: AppLoadingSpinnerSize.small),
              const SizedBox(width: Spacings.md),
              Text(
                'Uploading document…',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: AppTypography.wMedium,
                ),
              ),
              const Spacer(),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacings.xs),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
              borderRadius: BorderRadius.circular(Spacings.xs),
            ),
          ),
        ],
      ),
    );
  }

  // ── Document Processing Status ──────────────────────────────────────

  Widget _buildDocumentProcessingStatus() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final doc = _currentDocument!;

    final (Color color, IconData icon, String label) = switch (doc.status) {
      DocumentStatus.uploading => (AppColors.infoOf(cs.brightness), Icons.cloud_upload_rounded, 'Uploading'),
      DocumentStatus.uploaded => (AppColors.infoOf(cs.brightness), Icons.cloud_done_rounded, 'Uploaded'),
      DocumentStatus.processing => (AppColors.warningOf(cs.brightness), Icons.sync_rounded, 'Processing'),
      DocumentStatus.completed => (AppColors.successOf(cs.brightness), Icons.check_circle_rounded, 'Completed'),
      DocumentStatus.failed => (AppColors.errorOf(cs.brightness), Icons.error_rounded, 'Failed'),
    };

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(icon, size: Spacings.lgIcon, color: color),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.fileName,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: Spacings.xs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.xs),
                      ),
                      child: Text(
                        label,
                        style: tt.labelSmall?.copyWith(
                          color: color,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      _formatFileSize(doc.fileSize),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (doc.status == DocumentStatus.failed && doc.errorMessage != null)
            AppIconButton(
              icon: Icons.info_outline_rounded,
              onPressed: () => AppDialog.showError(
                context: context,
                title: 'Processing Failed',
                message: doc.errorMessage!,
              ),
              variant: AppIconButtonVariant.standard,
              tooltip: 'Error details',
              color: AppColors.errorOf(cs.brightness),
            ),
        ],
      ),
    );
  }

  // ── Extracted Text Preview ─────────────────────────────────────────

  Widget _buildExtractedTextPreview() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(
              () => _isExtractedTextExpanded = !_isExtractedTextExpanded),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: Spacings.mdIcon,
                color: cs.primary,
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Extracted Text',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Icon(
                _isExtractedTextExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_isExtractedTextExpanded) ...[
          const SizedBox(height: Spacings.sm),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: SingleChildScrollView(
              child: Text(
                _currentDocument!.extractedText!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Identified Topics ──────────────────────────────────────────────

  Widget _buildIdentifiedTopics() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final topics = _currentDocument!.identifiedTopics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label_outline_rounded, size: Spacings.mdIcon, color: cs.primary),
            const SizedBox(width: Spacings.sm),
            Text(
              'Identified Topics',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        Wrap(
          spacing: Spacings.sm,
          runSpacing: Spacings.sm,
          children: topics.map((topic) {
            final name = topic['name'] as String? ?? 'Topic';
            return Chip(
              label: Text(name),
              avatar: Icon(Icons.topic_outlined, size: Spacings.smIcon),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Suggested Objectives ───────────────────────────────────────────

  Widget _buildSuggestedObjectives() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final objectives = _currentDocument!.suggestedObjectives;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_outlined, size: Spacings.mdIcon, color: cs.primary),
            const SizedBox(width: Spacings.sm),
            Text(
              'Suggested Objectives',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        ...objectives.map((obj) {
          final text = obj['objective'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: Spacings.smIcon,
                  color: AppColors.successOf(cs.brightness),
                ),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Text(
                    text,
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Generation Settings ────────────────────────────────────────────

  Widget _buildGenerationSettings() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: Spacings.mdIcon, color: cs.primary),
              const SizedBox(width: Spacings.sm),
              Text(
                'Generation Settings',
                style: tt.titleSmall?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          AppDropdownField<DifficultyLevel>(
            label: 'Difficulty',
            items: DifficultyLevel.values,
            selectedItem: _selectedDifficulty,
            onChanged: (val) {
              if (val != null) setState(() => _selectedDifficulty = val);
            },
            itemLabel: (d) => d.label,
            prefixIcon: Icons.signal_cellular_alt_rounded,
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Text(
                'Number of Questions',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: AppTypography.wMedium,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacings.md,
                  vertical: Spacings.xs,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(context.isDarkMode ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Text(
                  '$_numQuestions',
                  style: tt.titleSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wBold,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _numQuestions.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_numQuestions',
            onChanged: (val) => setState(() => _numQuestions = val.round()),
          ),
        ],
      ),
    );
  }

  // ── Generating State ───────────────────────────────────────────────

  Widget _buildGeneratingState() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(Spacings.xl),
        child: Column(
          children: [
            AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            const SizedBox(height: Spacings.lg),
            Text(
              'Generating questions from document…',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: AppTypography.wMedium,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'This may take a moment depending on the document size.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────

  Future<void> _handleFileUpload() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentDocument = null;
    });

    // Simulate upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() => _uploadProgress = i / 100.0);
    }

    // Simulate creating document entity
    setState(() {
      _isUploading = false;
      _currentDocument = DocumentUploadEntity(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        schoolId: 'school_1',
        uploadedBy: 'user_1',
        fileName: 'sample_document.pdf',
        fileUrl: 'https://example.com/docs/sample.pdf',
        fileSize: 1024 * 512,
        mimeType: 'application/pdf',
        documentType: 'pdf',
        status: DocumentStatus.uploaded,
        createdAt: DateTime.now(),
      );
    });

    // Simulate processing
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _currentDocument = _currentDocument!.copyWith(
        status: DocumentStatus.completed,
        extractedText:
            'This is a sample extracted text from the uploaded document. '
            'It contains educational content about various subjects that can '
            'be used for question generation. The AI has processed the document '
            'and identified key topics and learning objectives.',
        identifiedTopics: [
          {'name': 'Photosynthesis'},
          {'name': 'Cell Biology'},
          {'name': 'Plant Anatomy'},
        ],
        suggestedObjectives: [
          {'objective': 'Explain the process of photosynthesis'},
          {'objective': 'Identify the main components of a plant cell'},
          {'objective': 'Describe the role of chlorophyll in light absorption'},
        ],
        processedAt: DateTime.now(),
      );
    });
  }

  Future<void> _handleGenerateFromDocument() async {
    if (_currentDocument == null) return;

    setState(() => _isGenerating = true);

    // Simulate generation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _generatedQuestions.clear();
      for (int i = 0; i < _numQuestions; i++) {
        _generatedQuestions.add(GeneratedQuestionEntity(
          id: 'gen_${DateTime.now().millisecondsSinceEpoch}_$i',
          generationRequestId: _currentDocument!.questionGenerationRequestId ?? 'req_1',
          schoolId: 'school_1',
          questionType: QuestionType.multipleChoice,
          difficulty: _selectedDifficulty,
          bloomLevel: BloomTaxonomy.remember,
          content: 'Sample generated question ${i + 1} from document content about photosynthesis.',
          answerOptions: [
            {'label': 'A', 'text': 'Option A', 'is_correct': true},
            {'label': 'B', 'text': 'Option B', 'is_correct': false},
            {'label': 'C', 'text': 'Option C', 'is_correct': false},
            {'label': 'D', 'text': 'Option D', 'is_correct': false},
          ],
          explanation: 'This is the explanation for question ${i + 1}.',
          confidenceScore: 0.85,
          reviewStatus: ReviewStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
