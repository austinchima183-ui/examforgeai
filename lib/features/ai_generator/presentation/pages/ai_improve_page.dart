import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ai_entities.dart';
import '../widgets/ai_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════
// AI IMPROVE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Question Improvement page with improvement type selector, custom
/// instructions, before/after comparison view, accept/reject buttons,
/// and improvement history.
///
/// ```dart
/// AiImprovePage()
/// ```
class AiImprovePage extends StatefulWidget {
  const AiImprovePage({super.key});

  @override
  State<AiImprovePage> createState() => _AiImprovePageState();
}

class _AiImprovePageState extends State<AiImprovePage> {
  GeneratedQuestionEntity? _selectedQuestion;
  String? _selectedImprovementType;
  final _customInstructionsController = TextEditingController();
  QuestionImprovementEntity? _currentImprovement;
  final List<QuestionImprovementEntity> _improvementHistory = [];
  bool _isImproving = false;

  static const _improvementTypes = [
    _ImprovementTypeConfig(
      type: 'Rewrite',
      icon: Icons.edit_note_rounded,
      description: 'Rewrite the question for clarity and conciseness',
    ),
    _ImprovementTypeConfig(
      type: 'Simplify',
      icon: Icons.trending_down_rounded,
      description: 'Simplify language and reduce complexity',
    ),
    _ImprovementTypeConfig(
      type: 'Make Difficult',
      icon: Icons.trending_up_rounded,
      description: 'Increase difficulty level and cognitive demand',
    ),
    _ImprovementTypeConfig(
      type: 'Make Easy',
      icon: Icons.thumb_down_outlined,
      description: 'Reduce difficulty and simplify concepts',
    ),
    _ImprovementTypeConfig(
      type: 'New Distractors',
      icon: Icons.shuffle_rounded,
      description: 'Generate new plausible distractor options',
    ),
    _ImprovementTypeConfig(
      type: 'Improve Explanation',
      icon: Icons.lightbulb_outline_rounded,
      description: 'Enhance the explanation and worked solution',
    ),
    _ImprovementTypeConfig(
      type: 'Translate',
      icon: Icons.translate_rounded,
      description: 'Translate the question to another language',
    ),
    _ImprovementTypeConfig(
      type: 'Change Type',
      icon: Icons.transform_rounded,
      description: 'Convert to a different question type',
    ),
    _ImprovementTypeConfig(
      type: 'Generate Similar',
      icon: Icons.content_copy_rounded,
      description: 'Create a similar question with variations',
    ),
    _ImprovementTypeConfig(
      type: 'Expand to Case Study',
      icon: Icons.expand_rounded,
      description: 'Expand into a case study with scenario context',
    ),
  ];

  @override
  void dispose() {
    _customInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Improve Question',
        actions: [
          if (_improvementHistory.isNotEmpty)
            AppIconButton(
              icon: Icons.history_rounded,
              onPressed: _showHistory,
              tooltip: 'Improvement History',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacings.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Question selector ────────────────────────────────────
            Text(
              'Select Question',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            _buildQuestionSelector(),

            Spacings.sectionGap,

            // ── Improvement type selector ────────────────────────────
            Text(
              'Improvement Type',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            _buildImprovementTypeGrid(isMobile),

            Spacings.sectionGap,

            // ── Custom instructions ─────────────────────────────────
            AppTextField(
              controller: _customInstructionsController,
              label: 'Custom Instructions',
              hint: 'Any specific instructions for the improvement…',
              maxLines: 3,
              minLines: 2,
              prefixIcon: Icons.edit_note_rounded,
            ),

            Spacings.sectionGap,

            // ── Improve button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Improve Question',
                onPressed: _canImprove() ? _handleImprove : null,
                variant: AppButtonVariant.elevated,
                size: AppButtonSize.large,
                icon: Icons.auto_fix_high_rounded,
                isLoading: _isImproving,
                isDisabled: !_canImprove(),
              ),
            ),

            // ── Before/After comparison ─────────────────────────────
            if (_currentImprovement != null) ...[
              Spacings.sectionGap,
              _buildBeforeAfterComparison(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Question Selector ──────────────────────────────────────────────

  Widget _buildQuestionSelector() {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    if (_selectedQuestion == null) {
      return AppCard(
        onTap: () {
          // In production, this would open a question picker
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: cs.primary),
            const SizedBox(width: Spacings.sm),
            Text(
              'Select a generated question to improve',
              style: tt.bodyMedium?.copyWith(color: cs.primary),
            ),
          ],
        ),
      );
    }

    return GeneratedQuestionCard(
      question: _selectedQuestion!,
      onImprove: null,
    );
  }

  // ── Improvement Type Grid ──────────────────────────────────────────

  Widget _buildImprovementTypeGrid(bool isMobile) {
    final crossCount = isMobile ? 2 : 4;

    return GridView.count(
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacings.sm,
      crossAxisSpacing: Spacings.sm,
      childAspectRatio: isMobile ? 1.4 : 1.8,
      children: _improvementTypes.map((config) {
        final isSelected = _selectedImprovementType == config.type;
        return _ImprovementTypeCard(
          config: config,
          isSelected: isSelected,
          onTap: () => setState(() {
            _selectedImprovementType =
                isSelected ? null : config.type;
          }),
        );
      }).toList(),
    );
  }

  // ── Before/After Comparison ────────────────────────────────────────

  Widget _buildBeforeAfterComparison() {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final improvement = _currentImprovement!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.compare_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Before / After Comparison',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),

        // Before
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.lg),
          decoration: BoxDecoration(
            color: AppColors.errorOf(cs.brightness).withValues(alpha: isDark ? 0.10 : 0.05,
            ),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            border: Border.all(
              color: AppColors.errorOf(cs.brightness).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.remove_circle_outline_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.errorOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'BEFORE',
                    style: tt.labelMedium?.copyWith(
                      color: AppColors.errorOf(cs.brightness),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                improvement.originalContent,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),

        // Arrow
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacings.sm),
            child: Icon(
              Icons.arrow_downward_rounded,
              color: cs.primary,
              size: Spacings.lgIcon,
            ),
          ),
        ),

        // After
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.lg),
          decoration: BoxDecoration(
            color: AppColors.successOf(cs.brightness).withValues(alpha: isDark ? 0.10 : 0.05,
            ),
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            border: Border.all(
              color: AppColors.successOf(cs.brightness).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: Spacings.smIcon,
                    color: AppColors.successOf(cs.brightness),
                  ),
                  const SizedBox(width: Spacings.xs),
                  Text(
                    'AFTER',
                    style: tt.labelMedium?.copyWith(
                      color: AppColors.successOf(cs.brightness),
                      fontWeight: AppTypography.wSemiBold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                improvement.improvedContent,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacings.lg),

        // Accept / Reject buttons
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Accept Improvement',
                onPressed: () => _acceptImprovement(improvement),
                variant: AppButtonVariant.elevated,
                icon: Icons.check_rounded,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: AppButton(
                label: 'Reject',
                onPressed: () => _rejectImprovement(),
                variant: AppButtonVariant.outlined,
                icon: Icons.close_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────

  bool _canImprove() {
    return _selectedQuestion != null &&
        _selectedImprovementType != null &&
        !_isImproving;
  }

  Future<void> _handleImprove() async {
    if (!_canImprove()) return;

    setState(() => _isImproving = true);

    // Simulate improvement (in production, call the provider)
    await Future.delayed(const Duration(seconds: 2));

    final improvement = QuestionImprovementEntity(
      id: 'imp_${DateTime.now().millisecondsSinceEpoch}',
      generatedQuestionId: _selectedQuestion!.id,
      improvementType: _selectedImprovementType!,
      provider: AiProvider.openai,
      originalContent: _selectedQuestion!.content,
      improvedContent:
          '${_selectedQuestion!.content}\n\n[Improved via ${_selectedImprovementType!}] — The content has been refined for clarity, accuracy, and better alignment with the specified cognitive level.',
      createdAt: DateTime.now(),
    );

    setState(() {
      _currentImprovement = improvement;
      _improvementHistory.insert(0, improvement);
      _isImproving = false;
    });
  }

  void _acceptImprovement(QuestionImprovementEntity improvement) {
    setState(() {
      _selectedQuestion = _selectedQuestion?.copyWith(
        content: improvement.improvedContent,
        isEdited: true,
      );
      _currentImprovement = null;
      _selectedImprovementType = null;
      _customInstructionsController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Improvement applied successfully'),
        backgroundColor: AppColors.successOf(context.colorScheme.brightness),
      ),
    );
  }

  void _rejectImprovement() {
    setState(() {
      _currentImprovement = null;
    });
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Spacings.lgRadius),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacings.lg),
                  Text(
                    'Improvement History',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _improvementHistory.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: Spacings.sm),
                      itemBuilder: (context, index) {
                        final imp = _improvementHistory[index];
                        return AppInfoCard(
                          title: imp.improvementType,
                          subtitle: imp.provider.displayName,
                          icon: Icons.auto_fix_high_rounded,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPERS
// ═══════════════════════════════════════════════════════════════════════

class _ImprovementTypeConfig {
  const _ImprovementTypeConfig({
    required this.type,
    required this.icon,
    required this.description,
  });
  final String type;
  final IconData icon;
  final String description;
}

class _ImprovementTypeCard extends StatelessWidget {
  const _ImprovementTypeCard({
    required this.config,
    required this.isSelected,
    required this.onTap,
  });
  final _ImprovementTypeConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: isDark ? 0.20 : 0.10)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              config.icon,
              size: Spacings.mdIcon,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(height: Spacings.xs),
            Text(
              config.type,
              style: tt.labelMedium?.copyWith(
                color: isSelected ? cs.primary : cs.onSurface,
                fontWeight: AppTypography.wSemiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              config.description,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
