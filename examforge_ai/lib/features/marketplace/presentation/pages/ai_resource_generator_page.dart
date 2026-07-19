import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/marketplace_entities.dart';
import '../providers/seller_provider.dart';
import '../providers/quality_check_provider.dart';
import '../widgets/marketplace_widgets.dart';
import 'create_product_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AI RESOURCE GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// AI-powered resource generator that allows sellers to create educational
/// content with AI assistance and then publish it as a marketplace product.
///
/// Flow:
/// 1. Select a resource type from the grid
/// 2. Configure generation parameters
/// 3. Generate with AI → preview & edit
/// 4. Accept & redirect to [CreateProductPage] with pre-populated data
///
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => AiResourceGeneratorPage(),
/// ));
/// ```
class AiResourceGeneratorPage extends ConsumerStatefulWidget {
  const AiResourceGeneratorPage({super.key});

  @override
  ConsumerState<AiResourceGeneratorPage> createState() =>
      _AiResourceGeneratorPageState();
}

class _AiResourceGeneratorPageState
    extends ConsumerState<AiResourceGeneratorPage> {
  // ─── State ───────────────────────────────────────────────────────────

  _ResourceType? _selectedType;
  bool _isGenerating = false;
  bool _hasGenerated = false;

  // Configuration
  final _subjectCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _numItemsCtrl = TextEditingController(text: '10');
  final _additionalInstructionsCtrl = TextEditingController();

  String? _selectedClassLevel;
  String? _selectedCurriculum;
  String? _selectedDifficulty;
  String? _selectedLanguage;

  // Generated content
  final _generatedContentCtrl = TextEditingController();

  // History (local mock)
  final List<_GeneratedResource> _history = [];

  // ─── Constants ───────────────────────────────────────────────────────

  static const _classLevels = [
    'Primary 1', 'Primary 2', 'Primary 3', 'Primary 4',
    'Primary 5', 'Primary 6', 'JSS1', 'JSS2', 'JSS3',
    'SS1', 'SS2', 'SS3', 'All Levels',
  ];

  static const _curricula = [
    'Nigerian', 'British', 'American', 'International', 'Other',
  ];

  static const _difficulties = ['Easy', 'Medium', 'Hard', 'Mixed'];

  static const _languages = [
    'English', 'French', 'Yoruba', 'Hausa', 'Igbo', 'Other',
  ];

  // ─── Lifecycle ───────────────────────────────────────────────────────

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    _numItemsCtrl.dispose();
    _additionalInstructionsCtrl.dispose();
    _generatedContentCtrl.dispose();
    super.dispose();
  }

  // ─── Generate with AI (simulated) ────────────────────────────────────

  Future<void> _generateWithAi() async {
    if (!_validateConfiguration()) return;

    setState(() => _isGenerating = true);

    // Simulate AI generation delay
    await Future.delayed(const Duration(seconds: 3));

    final numItems = int.tryParse(_numItemsCtrl.text) ?? 10;
    final typeLabel = _selectedType!.label;

    // Build simulated generated content
    final buffer = StringBuffer();
    buffer.writeln('# $typeLabel: ${_topicCtrl.text}');
    buffer.writeln();
    buffer.writeln('**Subject:** ${_subjectCtrl.text}');
    buffer.writeln('**Class Level:** $_selectedClassLevel');
    buffer.writeln('**Curriculum:** $_selectedCurriculum');
    buffer.writeln('**Difficulty:** $_selectedDifficulty');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    switch (_selectedType!) {
      case _ResourceType.lessonNotes:
        buffer.writeln('## Lesson Notes');
        buffer.writeln();
        buffer.writeln('### Learning Objectives');
        buffer.writeln('By the end of this lesson, students should be able to:');
        for (var i = 1; i <= 3; i++) {
          buffer.writeln('$i. Objective $i for ${_topicCtrl.text}');
        }
        buffer.writeln();
        buffer.writeln('### Introduction');
        buffer.writeln(
            'This lesson introduces key concepts in ${_topicCtrl.text} '
            'for $_selectedClassLevel students following the $_selectedCurriculum curriculum.');
        buffer.writeln();
        buffer.writeln('### Main Content');
        for (var i = 1; i <= numItems.clamp(3, 8); i++) {
          buffer.writeln();
          buffer.writeln('#### Section $i');
          buffer.writeln('Detailed explanation of concept $i...');
          buffer.writeln('- Key point A');
          buffer.writeln('- Key point B');
          buffer.writeln('- Key point C');
        }
        buffer.writeln();
        buffer.writeln('### Summary');
        buffer.writeln('Summary of the key takeaways from this lesson.');
        buffer.writeln();
        buffer.writeln('### Assessment Questions');
        for (var i = 1; i <= 5; i++) {
          buffer.writeln('$i. Assessment question $i?');
        }

      case _ResourceType.worksheets:
        buffer.writeln('## Worksheet: ${_topicCtrl.text}');
        buffer.writeln();
        buffer.writeln('**Instructions:** Answer all questions. Show your working.');
        buffer.writeln();
        buffer.writeln('### Section A: Multiple Choice');
        for (var i = 1; i <= (numItems / 2).ceil(); i++) {
          buffer.writeln();
          buffer.writeln('$i. Question $i about ${_topicCtrl.text}?');
          buffer.writeln('   a) Option A');
          buffer.writeln('   b) Option B');
          buffer.writeln('   c) Option C');
          buffer.writeln('   d) Option D');
        }
        buffer.writeln();
        buffer.writeln('### Section B: Short Answer');
        for (var i = 1; i <= (numItems / 2).floor(); i++) {
          buffer.writeln('$i. Short answer question $i?');
        }

      case _ResourceType.assessments:
        buffer.writeln('## Assessment: ${_topicCtrl.text}');
        buffer.writeln();
        buffer.writeln('**Time Allowed:** 45 minutes');
        buffer.writeln('**Total Marks:** ${numItems * 2}');
        buffer.writeln();
        for (var i = 1; i <= numItems; i++) {
          buffer.writeln();
          buffer.writeln('### Question $i [${2} marks]');
          buffer.writeln('Assessment question $i about ${_topicCtrl.text}.');
          if (i <= numItems / 2) {
            buffer.writeln('   a) Option A');
            buffer.writeln('   b) Option B');
            buffer.writeln('   c) Option C');
            buffer.writeln('   d) Option D');
          }
        }

      case _ResourceType.practiceQuestions:
        buffer.writeln('## Practice Questions: ${_topicCtrl.text}');
        buffer.writeln();
        for (var i = 1; i <= numItems; i++) {
          buffer.writeln();
          buffer.writeln('### Question $i');
          buffer.writeln('Practice question $i about ${_topicCtrl.text}.');
          buffer.writeln();
          buffer.writeln('**Answer:**');
          buffer.writeln('Model answer for question $i...');
        }

      case _ResourceType.flashcards:
        buffer.writeln('## Flashcards: ${_topicCtrl.text}');
        buffer.writeln();
        for (var i = 1; i <= numItems; i++) {
          buffer.writeln('---');
          buffer.writeln();
          buffer.writeln('### Card $i');
          buffer.writeln();
          buffer.writeln('**Front:**');
          buffer.writeln('Key term or question $i about ${_topicCtrl.text}');
          buffer.writeln();
          buffer.writeln('**Back:**');
          buffer.writeln('Definition or answer for item $i...');
        }

      case _ResourceType.slides:
        buffer.writeln('## Presentation Slides: ${_topicCtrl.text}');
        buffer.writeln();
        for (var i = 1; i <= numItems.clamp(5, 15); i++) {
          buffer.writeln('---');
          buffer.writeln();
          buffer.writeln('### Slide $i');
          buffer.writeln();
          buffer.writeln('**Title:** Slide $i Title');
          buffer.writeln();
          buffer.writeln('**Content:**');
          buffer.writeln('- Bullet point 1');
          buffer.writeln('- Bullet point 2');
          buffer.writeln('- Bullet point 3');
          buffer.writeln();
          buffer.writeln('**Speaker Notes:**');
          buffer.writeln('Additional context for slide $i...');
        }

      case _ResourceType.studyGuides:
        buffer.writeln('## Study Guide: ${_topicCtrl.text}');
        buffer.writeln();
        buffer.writeln('### Overview');
        buffer.writeln(
            'This study guide covers ${_topicCtrl.text} for '
            '$_selectedClassLevel students following the $_selectedCurriculum curriculum.');
        buffer.writeln();
        buffer.writeln('### Key Concepts');
        for (var i = 1; i <= numItems.clamp(5, 12); i++) {
          buffer.writeln();
          buffer.writeln('#### $i. Concept $i');
          buffer.writeln('Explanation of concept $i...');
          buffer.writeln('- Key point');
          buffer.writeln('- Example');
          buffer.writeln('- Common mistakes to avoid');
        }
        buffer.writeln();
        buffer.writeln('### Review Questions');
        for (var i = 1; i <= 5; i++) {
          buffer.writeln('$i. Review question $i?');
        }
    }

    _generatedContentCtrl.text = buffer.toString();

    // Add to history
    _history.insert(0, _GeneratedResource(
      type: _selectedType!,
      title: _topicCtrl.text,
      subject: _subjectCtrl.text,
      classLevel: _selectedClassLevel ?? '',
      generatedAt: DateTime.now(),
    ));

    // Keep only last 5
    if (_history.length > 5) {
      _history.removeRange(5, _history.length);
    }

    setState(() {
      _isGenerating = false;
      _hasGenerated = true;
    });
  }

  // ─── Validation ──────────────────────────────────────────────────────

  bool _validateConfiguration() {
    if (_selectedType == null) {
      _showError('Please select a resource type');
      return false;
    }
    if (_subjectCtrl.text.trim().isEmpty) {
      _showError('Subject is required');
      return false;
    }
    if (_topicCtrl.text.trim().isEmpty) {
      _showError('Topic / Title is required');
      return false;
    }
    if (_selectedClassLevel == null) {
      _showError('Class level is required');
      return false;
    }
    if (_selectedCurriculum == null) {
      _showError('Curriculum is required');
      return false;
    }
    final numItems = int.tryParse(_numItemsCtrl.text);
    if (numItems == null || numItems < 1 || numItems > 100) {
      _showError('Number of items must be between 1 and 100');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    context.scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Accept & Continue ───────────────────────────────────────────────

  void _acceptAndContinue() {
    // Determine the product type mapping
    final productType = switch (_selectedType!) {
      _ResourceType.lessonNotes => MarketplaceProductType.lessonNote,
      _ResourceType.worksheets => MarketplaceProductType.worksheet,
      _ResourceType.assessments => MarketplaceProductType.assessmentRubric,
      _ResourceType.practiceQuestions => MarketplaceProductType.questionBank,
      _ResourceType.flashcards => MarketplaceProductType.flashcards,
      _ResourceType.slides => MarketplaceProductType.teachingSlides,
      _ResourceType.studyGuides => MarketplaceProductType.studyGuide,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateProductPage(
          // Pass pre-populated data as route arguments would be ideal,
          // but since CreateProductPage doesn't accept them directly,
          // we navigate and the user has the generated content ready.
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Resource Generator',
        actions: [
          AppIconButton(
            icon: Icons.history,
            onPressed: _showHistory,
            variant: AppIconButtonVariant.standard,
            tooltip: 'Generation History',
          ),
          const SizedBox(width: Spacings.sm),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: Spacings.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disclaimer banner
                _buildDisclaimerBanner(cs, tt),
                Spacings.sectionGap,

                // Resource type selector
                _buildResourceTypeSelector(cs, tt),
                Spacings.sectionGap,

                // Configuration form
                if (_selectedType != null) ...[
                  _buildConfigurationForm(cs, tt),
                  Spacings.sectionGap,
                ],

                // Generated content preview
                if (_hasGenerated) ...[
                  _buildGeneratedContentPreview(cs, tt),
                  Spacings.sectionGap,
                ],

                // Recent history (last 5)
                if (_history.isNotEmpty) ...[
                  _buildRecentHistory(cs, tt),
                  Spacings.sectionGap,
                ],

                // Bottom padding
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Loading overlay
          if (_isGenerating)
            AppLoadingOverlay(
              message: 'Generating your ${_selectedType?.label.toLowerCase() ?? 'resource'} with AI...',
            ),
        ],
      ),
    );
  }

  // ─── Disclaimer banner ───────────────────────────────────────────────

  Widget _buildDisclaimerBanner(ColorScheme cs, TextTheme tt) {
    return AppCard(
      color: AppColors.infoLight.withValues(alpha: context.isDarkMode ? 0.15 : 1.0),
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: Spacings.mdIcon),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Generated Content',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  'Content generated by AI should be reviewed for accuracy and '
                  'appropriateness before publishing. AI-generated products will be '
                  'clearly marked in the marketplace. You are responsible for the '
                  'quality and correctness of the final product.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Resource type selector ──────────────────────────────────────────

  Widget _buildResourceTypeSelector(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Resource Type',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          'Choose the type of educational resource to generate.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: Spacings.lg),
        GridView.count(
          crossAxisCount: context.isMobile ? 2 : context.isTablet ? 3 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Spacings.sm,
          crossAxisSpacing: Spacings.sm,
          childAspectRatio: 1.4,
          children: _ResourceType.values.map((type) {
            final isSelected = _selectedType == type;
            return AppCard(
              borderColor: isSelected ? cs.primary : null,
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.05)
                  : null,
              onTap: () => setState(() {
                _selectedType = type;
                _hasGenerated = false;
              }),
              padding: const EdgeInsets.all(Spacings.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Spacings.sm),
                    decoration: BoxDecoration(
                      color: (isSelected ? cs.primary : type.color)
                          .withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(Spacings.smRadius),
                    ),
                    child: Icon(
                      type.icon,
                      size: Spacings.lgIcon,
                      color: isSelected ? cs.primary : type.color,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    type.label,
                    style: tt.labelMedium?.copyWith(
                      color: isSelected ? cs.primary : cs.onSurface,
                      fontWeight: isSelected
                          ? AppTypography.wSemiBold
                          : AppTypography.wMedium,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Configuration form ──────────────────────────────────────────────

  Widget _buildConfigurationForm(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          'Customize the AI generation parameters.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        Spacings.itemGap,

        AppTextField(
          label: 'Subject',
          hint: 'e.g. Mathematics, Physics, English',
          controller: _subjectCtrl,
          isRequired: true,
          prefixIcon: Icons.book_outlined,
        ),
        Spacings.itemGap,

        AppDropdownField<String>(
          label: 'Class Level',
          hint: 'Select class level',
          items: _classLevels,
          selectedItem: _selectedClassLevel,
          onChanged: (v) => setState(() => _selectedClassLevel = v),
          itemLabel: (l) => l,
          isRequired: true,
          prefixIcon: Icons.school_outlined,
        ),
        Spacings.itemGap,

        AppDropdownField<String>(
          label: 'Curriculum',
          hint: 'Select curriculum',
          items: _curricula,
          selectedItem: _selectedCurriculum,
          onChanged: (v) => setState(() => _selectedCurriculum = v),
          itemLabel: (c) => c,
          isRequired: true,
          prefixIcon: Icons.menu_book_outlined,
        ),
        Spacings.itemGap,

        AppTextField(
          label: 'Topic / Title',
          hint: 'e.g. Quadratic Equations, Newton\'s Laws',
          controller: _topicCtrl,
          isRequired: true,
          prefixIcon: Icons.title,
        ),
        Spacings.itemGap,

        AppTextField(
          label: 'Number of Items',
          hint: 'e.g. 10 questions, 15 flashcards',
          controller: _numItemsCtrl,
          isRequired: true,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.format_list_numbered,
        ),
        Spacings.itemGap,

        AppDropdownField<String>(
          label: 'Difficulty Level',
          hint: 'Select difficulty',
          items: _difficulties,
          selectedItem: _selectedDifficulty,
          onChanged: (v) => setState(() => _selectedDifficulty = v),
          itemLabel: (d) => d,
          prefixIcon: Icons.signal_cellular_alt,
        ),
        Spacings.itemGap,

        AppDropdownField<String>(
          label: 'Language',
          hint: 'Select language',
          items: _languages,
          selectedItem: _selectedLanguage,
          onChanged: (v) => setState(() => _selectedLanguage = v),
          itemLabel: (l) => l,
          prefixIcon: Icons.language,
        ),
        Spacings.itemGap,

        AppTextField(
          label: 'Additional Instructions (optional)',
          hint: 'Any specific requirements or focus areas...',
          controller: _additionalInstructionsCtrl,
          maxLines: 3,
          minLines: 2,
        ),
        Spacings.itemGap,

        // Generate button
        AppButton(
          label: 'Generate with AI',
          onPressed: _generateWithAi,
          variant: AppButtonVariant.elevated,
          icon: Icons.auto_awesome,
          fullWidth: true,
          isLoading: _isGenerating,
        ),
      ],
    );
  }

  // ─── Generated content preview ───────────────────────────────────────

  Widget _buildGeneratedContentPreview(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.success, size: Spacings.mdIcon),
            const SizedBox(width: Spacings.sm),
            Text(
              'Generated Content',
              style: tt.titleLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            AppButton(
              label: 'Regenerate',
              onPressed: _generateWithAi,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.small,
              icon: Icons.refresh,
              isLoading: _isGenerating,
            ),
          ],
        ),
        const SizedBox(height: Spacings.xs),
        Text(
          'Review and edit the generated content below before publishing.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: Spacings.lg),

        // Editable text area
        AppTextField(
          controller: _generatedContentCtrl,
          maxLines: 20,
          minLines: 10,
          hint: 'Generated content will appear here...',
        ),
        Spacings.itemGap,

        // Action buttons
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Accept & Continue',
                onPressed: _acceptAndContinue,
                variant: AppButtonVariant.elevated,
                icon: Icons.check_circle_outline,
                fullWidth: true,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: AppButton(
                label: 'Regenerate',
                onPressed: _generateWithAi,
                variant: AppButtonVariant.outlined,
                icon: Icons.refresh,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Recent history ──────────────────────────────────────────────────

  Widget _buildRecentHistory(ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: cs.onSurfaceVariant, size: Spacings.mdIcon),
            const SizedBox(width: Spacings.sm),
            Text(
              'Recently Generated',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        ..._history.take(5).map((resource) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.sm),
            child: AppInfoCard(
              title: resource.title,
              subtitle:
                  '${resource.type.label} · ${resource.subject} · ${resource.classLevel}',
              icon: resource.type.icon,
              iconColor: resource.type.color,
              onTap: () {
                // Could re-load this resource for editing
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── History modal ───────────────────────────────────────────────────

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Spacings.lgRadius)),
      ),
      builder: (context) {
        final cs = context.colorScheme;
        final tt = context.textTheme;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacings.md),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
                  child: Row(
                    children: [
                      Text(
                        'Generation History',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacings.md),
                // List
                Expanded(
                  child: _history.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: Spacings.xlIcon,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: Spacings.md),
                              Text(
                                'No generation history yet',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.lg,
                          ),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Spacings.sm),
                          itemBuilder: (context, index) {
                            final resource = _history[index];
                            return AppInfoCard(
                              title: resource.title,
                              subtitle:
                                  '${resource.type.label} · ${resource.subject} · '
                                  '${_formatDate(resource.generatedAt)}',
                              icon: resource.type.icon,
                              iconColor: resource.type.color,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacings.sm,
                                  vertical: Spacings.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight.withValues(
                                    alpha: context.isDarkMode ? 0.15 : 1.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(Spacings.smRadius),
                                ),
                                child: Text(
                                  'Completed',
                                  style: tt.labelSmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: AppTypography.wSemiBold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Date formatting helper ──────────────────────────────────────────

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Resource types available for AI generation.
enum _ResourceType {
  lessonNotes(label: 'Lesson Notes', icon: Icons.menu_book_outlined, color: AppColors.info),
  worksheets(label: 'Worksheets', icon: Icons.assignment_outlined, color: AppColors.success),
  assessments(label: 'Assessments', icon: Icons.quiz_outlined, color: AppColors.warning),
  practiceQuestions(label: 'Practice Questions', icon: Icons.help_outline, color: AppColors.seed),
  flashcards(label: 'Flashcards', icon: Icons.style_outlined, color: const Color(0xFFEC4899)),
  slides(label: 'Slides', icon: Icons.slideshow_outlined, color: const Color(0xFF06B6D4)),
  studyGuides(label: 'Study Guides', icon: Icons.school_outlined, color: const Color(0xFF8B5CF6));

  const _ResourceType({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Lightweight model for tracking generated resources in history.
class _GeneratedResource {
  const _GeneratedResource({
    required this.type,
    required this.title,
    required this.subject,
    required this.classLevel,
    required this.generatedAt,
  });

  final _ResourceType type;
  final String title;
  final String subject;
  final String classLevel;
  final DateTime generatedAt;
}
