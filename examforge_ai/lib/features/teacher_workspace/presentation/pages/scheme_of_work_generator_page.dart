import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/spacings.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../routing/route_names.dart';
import '../../domain/entities/teacher_workspace_entities.dart';
import '../../domain/usecases/create_scheme_of_work_usecase.dart';
import '../../domain/usecases/generate_scheme_of_work_usecase.dart';
import '../providers/scheme_of_work_provider.dart';
import '../widgets/generate_questions_button.dart';

// ═══════════════════════════════════════════════════════════════════════
// SCHEME OF WORK GENERATOR PAGE
// ═══════════════════════════════════════════════════════════════════════

/// AI-powered Scheme of Work Generator page.
///
/// Teachers specify subject, class, curriculum, duration, and term
/// parameters and the AI generates a complete scheme of work with
/// weekly/monthly breakdowns including topics, objectives, activities,
/// resources, and assessments.
class SchemeOfWorkGeneratorPage extends ConsumerStatefulWidget {
  const SchemeOfWorkGeneratorPage({super.key});

  @override
  ConsumerState<SchemeOfWorkGeneratorPage> createState() =>
      _SchemeOfWorkGeneratorPageState();
}

class _SchemeOfWorkGeneratorPageState
    extends ConsumerState<SchemeOfWorkGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _classNameController = TextEditingController();
  final _termController = TextEditingController();

  CurriculumType _curriculum = CurriculumType.nigerian;
  PlanDuration _durationType = PlanDuration.term;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showResult = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _classNameController.dispose();
    _termController.dispose();
    super.dispose();
  }

  // ─── Form Validation ──────────────────────────────────────────────

  bool get _isFormValid {
    return _subjectController.text.trim().isNotEmpty;
  }

  // ─── Generate Scheme ──────────────────────────────────────────────

  void _generateScheme() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(schemeOfWorkProvider.notifier).generateScheme(
          GenerateSchemeOfWorkParams(
            subject: _subjectController.text.trim(),
            className: _classNameController.text.trim(),
            curriculum: _curriculum,
            durationType: _durationType,
            term: _termController.text.trim().isNotEmpty
                ? _termController.text.trim()
                : null,
          ),
        );
    setState(() => _showResult = true);
  }

  // ─── Save Scheme ──────────────────────────────────────────────────

  void _saveScheme() {
    final scheme = ref.read(schemeOfWorkProvider).currentScheme;
    if (scheme == null) return;

    ref.read(schemeOfWorkProvider.notifier).createScheme(
          CreateSchemeOfWorkParams(scheme: scheme),
        );
  }

  // ─── Date Picker ──────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(schemeOfWorkProvider);

    ref.listen<SchemeOfWorkState>(schemeOfWorkProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: cs.error,
          ),
        );
        ref.read(schemeOfWorkProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: cs.primary,
          ),
        );
        ref.read(schemeOfWorkProvider.notifier).clearSuccessMessage();
      }
    });

    return Scaffold(
      appBar: AppAppBar(
        title: 'AI Scheme of Work',
      ),
      body: state.isGenerating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
                  const SizedBox(height: Spacings.lg),
                  Text(
                    'Generating scheme of work...',
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.sm),
                  Text(
                    'This may take a moment',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: Spacings.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Input Form ─────────────────────────────────────
                  if (!_showResult || state.currentScheme == null) ...[
                    _buildFormSection(cs, tt, state),
                  ],

                  // ── Generated Result ──────────────────────────────
                  if (_showResult && state.currentScheme != null) ...[
                    _buildResultHeader(cs, tt, state.currentScheme!),
                    const SizedBox(height: Spacings.lg),
                    _buildBreakdownList(cs, tt, state.currentScheme!),
                    const SizedBox(height: Spacings.xl),
                    _buildActionButtons(cs, state),
                  ],
                ],
              ),
            ),
    );
  }

  // ─── Form Section ─────────────────────────────────────────────────

  Widget _buildFormSection(
      ColorScheme cs, TextTheme tt, SchemeOfWorkState state) {
    return Form(
      key: _formKey,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary, size: Spacings.lgIcon),
                const SizedBox(width: Spacings.sm),
                Text(
                  'Generate with AI',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.sm),
            Text(
              'Fill in the details below and let AI create a comprehensive scheme of work for you.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Spacings.xl),

            // Subject (required)
            AppTextField(
              label: 'Subject',
              hint: 'e.g. Mathematics',
              controller: _subjectController,
              prefixIcon: Icons.book_outlined,
              isRequired: true,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Subject is required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: Spacings.lg),

            // Class Name
            AppTextField(
              label: 'Class Name',
              hint: 'e.g. SS2, JSS3',
              controller: _classNameController,
              prefixIcon: Icons.school_outlined,
            ),
            const SizedBox(height: Spacings.lg),

            // Curriculum Dropdown
            AppDropdownField<CurriculumType>(
              label: 'Curriculum',
              items: CurriculumType.values,
              selectedItem: _curriculum,
              onChanged: (v) {
                if (v != null) setState(() => _curriculum = v);
              },
              itemLabel: (c) => c.label,
              prefixIcon: Icons.dashboard_outlined,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.lg),

            // Duration Type Dropdown
            AppDropdownField<PlanDuration>(
              label: 'Duration Type',
              items: PlanDuration.values,
              selectedItem: _durationType,
              onChanged: (v) {
                if (v != null) setState(() => _durationType = v);
              },
              itemLabel: (d) => d.label,
              prefixIcon: Icons.schedule_outlined,
              isRequired: true,
            ),
            const SizedBox(height: Spacings.lg),

            // Term
            AppTextField(
              label: 'Term',
              hint: 'e.g. First Term, Second Term',
              controller: _termController,
              prefixIcon: Icons.calendar_view_week_outlined,
            ),
            const SizedBox(height: Spacings.lg),

            // Start / End Date pickers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: AbsorbPointer(
                      child: AppTextField(
                        label: 'Start Date',
                        controller: TextEditingController(
                            text: _startDate != null
                                ? _formatDate(_startDate)
                                : ''),
                        prefixIcon: Icons.calendar_today_outlined,
                        readOnly: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndDate,
                    child: AbsorbPointer(
                      child: AppTextField(
                        label: 'End Date',
                        controller: TextEditingController(
                            text: _endDate != null
                                ? _formatDate(_endDate)
                                : ''),
                        prefixIcon: Icons.calendar_today_outlined,
                        readOnly: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacings.xxl),

            // Generate Button
            AppButton(
              label: 'Generate Scheme of Work',
              onPressed: _isFormValid ? _generateScheme : null,
              variant: AppButtonVariant.elevated,
              fullWidth: true,
              icon: Icons.auto_awesome,
              isLoading: state.isGenerating,
              isDisabled: !_isFormValid || state.isBusy,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result Header ────────────────────────────────────────────────

  Widget _buildResultHeader(ColorScheme cs, TextTheme tt, SchemeOfWorkEntity scheme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & AI badge
          Row(
            children: [
              Expanded(
                child: Text(
                  scheme.title,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (scheme.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: Spacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Spacings.smRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: Spacings.smIcon, color: cs.onTertiaryContainer),
                      const SizedBox(width: Spacings.xs),
                      Text(
                        'AI Generated',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Metadata chips
          Wrap(
            spacing: Spacings.sm,
            runSpacing: Spacings.sm,
            children: [
              _buildMetadataChip(cs, tt, Icons.book_outlined, scheme.subject),
              if (scheme.className != null)
                _buildMetadataChip(
                    cs, tt, Icons.school_outlined, scheme.className!),
              _buildMetadataChip(
                  cs, tt, Icons.dashboard_outlined, scheme.curriculum.label),
              _buildMetadataChip(cs, tt, Icons.schedule_outlined,
                  scheme.durationType.label),
              if (scheme.term != null)
                _buildMetadataChip(
                    cs, tt, Icons.calendar_view_week_outlined, scheme.term!),
            ],
          ),
          const SizedBox(height: Spacings.md),

          // Version history indicator
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                'Version ${scheme.version}',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: Spacings.md),
              Icon(Icons.update_rounded,
                  size: Spacings.smIcon, color: cs.onSurfaceVariant),
              const SizedBox(width: Spacings.xs),
              Text(
                _formatDate(scheme.updatedAt),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(
      ColorScheme cs, TextTheme tt, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSecondaryContainer),
          const SizedBox(width: Spacings.xs),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: AppTypography.wMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Breakdown List ───────────────────────────────────────────────

  Widget _buildBreakdownList(
      ColorScheme cs, TextTheme tt, SchemeOfWorkEntity scheme) {
    final plans = scheme.weeklyPlans;
    if (plans.isEmpty) {
      return AppCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Text(
              'No weekly plans generated yet.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${scheme.durationType.label} Breakdown',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        ...plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: _buildBreakdownCard(cs, tt, index + 1, plan),
          );
        }),
      ],
    );
  }

  Widget _buildBreakdownCard(
      ColorScheme cs, TextTheme tt, int weekNumber, Map<String, dynamic> plan) {
    final topic = plan['topic'] as String? ?? 'Untitled';
    final objectives = (plan['objectives'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final activities = (plan['activities'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final resources = (plan['resources'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final assessment = plan['assessment'] as String? ?? '';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Center(
                  child: Text(
                    '$weekNumber',
                    style: tt.labelMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: AppTypography.wBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacings.sm),
              Expanded(
                child: Text(
                  topic,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),

          // Objectives
          if (objectives.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            _buildSubSection(
              cs,
              tt,
              Icons.flag_outlined,
              'Objectives',
              objectives,
            ),
          ],

          // Activities
          if (activities.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            _buildSubSection(
              cs,
              tt,
              Icons.local_activity_outlined,
              'Activities',
              activities,
            ),
          ],

          // Resources
          if (resources.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            _buildSubSection(
              cs,
              tt,
              Icons.inventory_2_outlined,
              'Resources',
              resources,
            ),
          ],

          // Assessment
          if (assessment.isNotEmpty) ...[
            const SizedBox(height: Spacings.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.assignment_outlined,
                    size: Spacings.smIcon, color: cs.tertiary),
                const SizedBox(width: Spacings.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assessment',
                        style: tt.labelMedium?.copyWith(
                          color: cs.tertiary,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        assessment,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(ColorScheme cs, TextTheme tt, IconData icon,
      String title, List<String> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: Spacings.smIcon, color: cs.primary),
        const SizedBox(width: Spacings.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const SizedBox(height: Spacings.xs),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u2022 ',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ───────────────────────────────────────────────

  Widget _buildActionButtons(ColorScheme cs, SchemeOfWorkState state) {
    final scheme = state.currentScheme;
    return Row(
      children: [
        // Save
        Expanded(
          child: AppButton(
            label: 'Save',
            onPressed: state.isCreating ? null : _saveScheme,
            variant: AppButtonVariant.elevated,
            icon: Icons.save_outlined,
            isLoading: state.isCreating,
          ),
        ),
        const SizedBox(width: Spacings.md),

        // Generate Questions
        if (scheme != null)
          Expanded(
            child: GenerateQuestionsButton(
              resourceType: 'scheme_of_work',
              resourceId: scheme.id,
            ),
          ),

        const SizedBox(width: Spacings.md),

        // Reset / New
        AppButton(
          label: 'New',
          onPressed: () {
            setState(() {
              _showResult = false;
              _subjectController.clear();
              _classNameController.clear();
              _termController.clear();
              _startDate = null;
              _endDate = null;
              _curriculum = CurriculumType.nigerian;
              _durationType = PlanDuration.term;
            });
          },
          variant: AppButtonVariant.outlined,
          icon: Icons.add_rounded,
          size: AppButtonSize.medium,
        ),
      ],
    );
  }
}
