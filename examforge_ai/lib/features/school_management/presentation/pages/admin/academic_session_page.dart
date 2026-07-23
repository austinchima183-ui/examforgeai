import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/academic_session_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// ACADEMIC SESSION PAGE (Admin)
// ═══════════════════════════════════════════════════════════════════════

/// Academic session management page. Lists all sessions with expandable
/// terms, and supports creating/editing sessions and setting the current one.
class AcademicSessionPage extends ConsumerStatefulWidget {
  const AcademicSessionPage({super.key, required this.schoolId});

  final String schoolId;

  @override
  ConsumerState<AcademicSessionPage> createState() =>
      _AcademicSessionPageState();
}

class _AcademicSessionPageState extends ConsumerState<AcademicSessionPage> {
  String? _expandedSessionId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(sessionListProvider.notifier).loadSessions(widget.schoolId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(sessionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Academic Sessions',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacings.sm),
            child: AppButton(
              label: 'New Session',
              onPressed: () => _showSessionDialog(context),
              variant: AppButtonVariant.elevated,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),
        ],
      ),
      body: _buildBody(context, state),
      floatingActionButton: context.isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showSessionDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Session'),
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
            ),
    );
  }

  Widget _buildBody(BuildContext context, SessionListState state) {
    if (state.isLoading && state.sessions.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && state.sessions.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () =>
            ref.read(sessionListProvider.notifier).loadSessions(widget.schoolId),
      );
    }

    if (state.sessions.isEmpty) {
      return AppEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No Academic Sessions',
        subtitle: 'Create your first academic session to get started.',
        actionLabel: 'Create Session',
        onAction: () => _showSessionDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(sessionListProvider.notifier).loadSessions(widget.schoolId),
      child: ListView.builder(
        padding: const EdgeInsets.all(Spacings.md),
        itemCount: state.sessions.length,
        itemBuilder: (context, index) {
          final session = state.sessions[index];
          final isExpanded = _expandedSessionId == session.id;

          return Padding(
            padding: const EdgeInsets.only(bottom: Spacings.md),
            child: _SessionCard(
              session: session,
              isExpanded: isExpanded,
              isCurrent: session.isCurrent,
              onToggleExpand: () {
                setState(() {
                  _expandedSessionId =
                      isExpanded ? null : session.id;
                });
                if (!isExpanded) {
                  // Load terms when expanding
                  ref
                      .read(termListProvider.notifier)
                      .loadTerms(session.id);
                }
              },
              onSetCurrent: () => _setCurrentSession(session.id),
              onEdit: () => _showSessionDialog(context, session: session),
              onAddTerm: () => _showTermDialog(context, session),
            ),
          );
        },
      ),
    );
  }

  Future<void> _setCurrentSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set as Current Session'),
        content: const Text(
          'This will set the selected session as the current active session. '
          'Any previously current session will be deactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Set Current'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(sessionListProvider.notifier).setCurrentSession(sessionId);
    }
  }

  void _showSessionDialog(BuildContext context, {AcademicSessionEntity? session}) {
    final isEdit = session != null;
    final nameCtrl = TextEditingController(text: session?.name);
    final yearCtrl = TextEditingController(text: session?.sessionYear);
    DateTime? startDate = session?.startDate;
    DateTime? endDate = session?.endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Session' : 'Create Session'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Session Name',
                  controller: nameCtrl,
                  isRequired: true,
                  hint: 'e.g., 2025/2026 Academic Session',
                  prefixIcon: Icons.label_outline,
                ),
                const SizedBox(height: Spacings.md),
                AppTextField(
                  label: 'Session Year',
                  controller: yearCtrl,
                  isRequired: true,
                  hint: 'e.g., 2025/2026',
                  prefixIcon: Icons.calendar_today_outlined,
                ),
                const SizedBox(height: Spacings.md),
                AppDateField(
                  label: 'Start Date',
                  selectedDate: startDate,
                  onDateSelected: (date) {
                    setDialogState(() => startDate = date);
                  },
                  isRequired: true,
                ),
                const SizedBox(height: Spacings.md),
                AppDateField(
                  label: 'End Date',
                  selectedDate: endDate,
                  onDateSelected: (date) {
                    setDialogState(() => endDate = date);
                  },
                  isRequired: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || yearCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                final newSession = AcademicSessionEntity(
                  id: session?.id ?? '',
                  schoolId: widget.schoolId,
                  name: nameCtrl.text.trim(),
                  sessionYear: yearCtrl.text.trim(),
                  startDate: startDate ?? DateTime.now(),
                  endDate: endDate ?? DateTime.now().add(const Duration(days: 365)),
                );
                if (isEdit) {
                  ref.read(sessionListProvider.notifier).updateSession(newSession);
                } else {
                  ref.read(sessionListProvider.notifier).createSession(newSession);
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermDialog(BuildContext context, AcademicSessionEntity session) {
    final nameCtrl = TextEditingController();
    TermType selectedTermType = TermType.firstTerm;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Term'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Term Name',
                  controller: nameCtrl,
                  isRequired: true,
                  hint: 'e.g., First Term 2025',
                  prefixIcon: Icons.label_outline,
                ),
                const SizedBox(height: Spacings.md),
                AppDropdownField<TermType>(
                  label: 'Term Type',
                  items: TermType.values.toList(),
                  selectedItem: selectedTermType,
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedTermType = v);
                    }
                  },
                  itemLabel: (v) => v.label,
                  prefixIcon: Icons.category_outlined,
                ),
                const SizedBox(height: Spacings.md),
                AppDateField(
                  label: 'Start Date',
                  selectedDate: startDate,
                  onDateSelected: (date) {
                    setDialogState(() => startDate = date);
                  },
                  isRequired: true,
                ),
                const SizedBox(height: Spacings.md),
                AppDateField(
                  label: 'End Date',
                  selectedDate: endDate,
                  onDateSelected: (date) {
                    setDialogState(() => endDate = date);
                  },
                  isRequired: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final term = TermEntity(
                  id: '',
                  academicSessionId: session.id,
                  schoolId: widget.schoolId,
                  name: nameCtrl.text.trim(),
                  termType: selectedTermType,
                  termNumber: selectedTermType.index + 1,
                  startDate: startDate ?? DateTime.now(),
                  endDate: endDate ?? DateTime.now().add(const Duration(days: 90)),
                );
                ref.read(termListProvider.notifier).createTerm(term);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SESSION CARD
// ═══════════════════════════════════════════════════════════════════════

class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.session,
    required this.isExpanded,
    required this.isCurrent,
    this.onToggleExpand,
    this.onSetCurrent,
    this.onEdit,
    this.onAddTerm,
  });

  final AcademicSessionEntity session;
  final bool isExpanded;
  final bool isCurrent;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onSetCurrent;
  final VoidCallback? onEdit;
  final VoidCallback? onAddTerm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Session Header ────────────────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(Spacings.mdRadius),
            child: Row(
              children: [
                // Current badge
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: isDark ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Text(
                      'CURRENT',
                      style: tt.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: AppTypography.wBold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(Spacings.fullRadius),
                    ),
                    child: Text(
                      session.isActive ? 'Active' : 'Archived',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: AppTypography.wSemiBold,
                      ),
                    ),
                  ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        '${session.sessionYear} · ${_formatDate(session.startDate)} – ${_formatDate(session.endDate)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: Spacings.mdIcon,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit session',
                ),
                if (!isCurrent)
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: Spacings.mdIcon,
                      color: AppColors.success,
                    ),
                    onPressed: onSetCurrent,
                    tooltip: 'Set as current',
                  ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // ── Expanded: Terms ───────────────────────────────────────
          if (isExpanded) ...[
            const Divider(height: Spacings.xl),
            _TermsList(
              sessionId: session.id,
              schoolId: session.schoolId,
              onAddTerm: onAddTerm,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TERMS LIST (shown when session is expanded)
// ═══════════════════════════════════════════════════════════════════════

class _TermsList extends ConsumerWidget {
  const _TermsList({
    required this.sessionId,
    required this.schoolId,
    this.onAddTerm,
  });

  final String sessionId;
  final String schoolId;
  final VoidCallback? onAddTerm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final termState = ref.watch(termListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Terms',
              style: tt.labelLarge?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: onAddTerm,
              icon: const Icon(Icons.add_rounded, size: Spacings.smIcon),
              label: const Text('Add Term'),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.sm),
        if (termState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(Spacings.lg),
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.small),
            ),
          )
        else if (termState.terms.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Spacings.md),
            child: Text(
              'No terms added yet',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          ...termState.terms.map((term) => _TermItem(
                term: term,
                onSetCurrent: () =>
                    ref.read(termListProvider.notifier).setCurrentTerm(term.id),
              ),),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TERM ITEM
// ═══════════════════════════════════════════════════════════════════════

class _TermItem extends StatelessWidget {
  const _TermItem({
    required this.term,
    this.onSetCurrent,
  });

  final TermEntity term;
  final VoidCallback? onSetCurrent;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final statusColor = _statusColor(term.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.sm),
      child: Container(
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
          border: Border.all(
            color: term.isCurrent
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        term.name,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (term.isCurrent) ...[
                        const SizedBox(width: Spacings.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacings.sm,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success
                                .withValues(alpha: isDark ? 0.20 : 0.12),
                            borderRadius:
                                BorderRadius.circular(Spacings.fullRadius),
                          ),
                          child: Text(
                            'CURRENT',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.success,
                              fontWeight: AppTypography.wBold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    '${term.termType.label} · ${_formatDate(term.startDate)} – ${_formatDate(term.endDate)}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!term.isCurrent && onSetCurrent != null)
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: Spacings.mdIcon,
                  color: AppColors.success,
                ),
                onPressed: onSetCurrent,
                tooltip: 'Set as current term',
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TermStatus status) {
    switch (status) {
      case TermStatus.active:
        return AppColors.success;
      case TermStatus.upcoming:
        return AppColors.warning;
      case TermStatus.completed:
        return AppColors.info;
      case TermStatus.archived:
        return AppColors.warningDark;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}';
  }
}
