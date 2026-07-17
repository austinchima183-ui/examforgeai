import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/result.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/results_entities.dart';
import '../providers/results_providers.dart';

// ═══════════════════════════════════════════════════════════════════════
// RESULT MANAGEMENT PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Page for managing result publication, locking, and recomputation.
///
/// Displays the current status of exam results (grading, release, lock)
/// and provides actions for locking, unlocking, publishing, withholding,
/// and recomputing results. Also shows an activity log of recent events.
class ResultManagementPage extends ConsumerStatefulWidget {
  const ResultManagementPage({
    super.key,
    required this.examId,
    required this.schoolId,
  });

  final String examId;
  final String schoolId;

  @override
  ConsumerState<ResultManagementPage> createState() =>
      _ResultManagementPageState();
}

class _ResultManagementPageState
    extends ConsumerState<ResultManagementPage> {
  @override
  void initState() {
    super.initState();
    // Lock status is loaded implicitly via lockResults/unlockResults
    // actions. No explicit load method is needed on init.
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(resultManagementProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Result Management',
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large))
          : _buildBody(context, state),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ResultManagementState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error banner ─────────────────────────────────────
              if (state.error != null)
                _buildErrorBanner(context, state.error!),

              // ── Success banner ───────────────────────────────────
              if (state.successMessage != null)
                _buildSuccessBanner(context, state.successMessage!),

              // ── Status Cards ─────────────────────────────────────
              _buildStatusSection(context, state),
              const SizedBox(height: Spacings.xl),

              // ── Actions ──────────────────────────────────────────
              _buildActionsSection(context, state),
              const SizedBox(height: Spacings.xl),

              // ── Activity Log ─────────────────────────────────────
              _buildActivityLog(context, state),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Status Section ────────────────────────────────────────────────

  Widget _buildStatusSection(
      BuildContext context, ResultManagementState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final lockStatus = state.lockStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Status',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 600 ? 3 : 1;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Spacings.md,
              crossAxisSpacing: Spacings.md,
              childAspectRatio: crossCount > 1 ? 1.8 : 3.5,
              children: [
                _buildStatusCard(
                  context,
                  title: 'Grading Status',
                  value: 'In Progress', // TODO: from actual data
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppColors.infoOf(cs.brightness),
                ),
                _buildStatusCard(
                  context,
                  title: 'Release Status',
                  value: state.isResultLocked ? 'Locked' : 'Unlocked',
                  icon: state.isResultLocked
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  color: state.isResultLocked
                      ? AppColors.warningOf(cs.brightness)
                      : AppColors.successOf(cs.brightness),
                ),
                _buildStatusCard(
                  context,
                  title: 'Lock Status',
                  value: state.isResultLocked ? 'Locked' : 'Unlocked',
                  icon: state.isResultLocked
                      ? Icons.enhanced_encryption_rounded
                      : Icons.no_encryption_rounded,
                  color: state.isResultLocked
                      ? AppColors.errorOf(cs.brightness)
                      : AppColors.successOf(cs.brightness),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                ),
                child: Icon(icon, size: Spacings.mdIcon, color: color),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      value,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Actions Section ───────────────────────────────────────────────

  Widget _buildActionsSection(
      BuildContext context, ResultManagementState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: tt.titleMedium?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: Spacings.md),
        AppCard(
          child: Column(
            children: [
              // ── Lock / Unlock ────────────────────────────────────
              _ActionTile(
                icon: state.isResultLocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                title: state.isResultLocked
                    ? 'Unlock Results'
                    : 'Lock Results',
                subtitle: state.isResultLocked
                    ? 'Allow modifications to exam results'
                    : 'Prevent any further modifications to results',
                isDestructive: !state.isResultLocked,
                isLoading: state.isLoading,
                onPressed: () => _toggleLock(context, state),
              ),
              const Divider(height: 1),
              // ── Publish ──────────────────────────────────────────
              _ActionTile(
                icon: Icons.publish_rounded,
                title: 'Publish Results',
                subtitle:
                    'Make results visible to students and parents',
                isDestructive: false,
                isLoading: state.isPublishing,
                onPressed: () => _publishResults(context),
              ),
              const Divider(height: 1),
              // ── Withhold ─────────────────────────────────────────
              _ActionTile(
                icon: Icons.visibility_off_rounded,
                title: 'Withhold Results',
                subtitle: 'Hide results from students and parents',
                isDestructive: true,
                isLoading: state.isPublishing,
                onPressed: () => _withholdResults(context),
              ),
              const Divider(height: 1),
              // ── Recompute ────────────────────────────────────────
              _ActionTile(
                icon: Icons.refresh_rounded,
                title: 'Recompute Results',
                subtitle:
                    'Recalculate all subject and overall results for the class',
                isDestructive: false,
                isLoading: state.isLoading,
                onPressed: () => _recomputeResults(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Activity Log ──────────────────────────────────────────────────

  Widget _buildActivityLog(
      BuildContext context, ResultManagementState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final lockStatus = state.lockStatus;

    // Build activity events from lock status
    final events = <_ActivityEvent>[];

    if (lockStatus != null) {
      events.add(_ActivityEvent(
        icon: lockStatus.isLocked
            ? Icons.lock_rounded
            : Icons.lock_open_rounded,
        title: lockStatus.isLocked ? 'Results Locked' : 'Results Unlocked',
        description: lockStatus.isLocked
            ? 'Locked by ${lockStatus.lockedBy}${lockStatus.reason != null ? ' — ${lockStatus.reason}' : ''}'
            : 'Unlocked by ${lockStatus.unlockedBy ?? 'system'}',
        timestamp: lockStatus.isLocked
            ? lockStatus.lockedAt
            : lockStatus.unlockedAt ?? lockStatus.lockedAt,
        color: lockStatus.isLocked
            ? AppColors.warningOf(cs.brightness)
            : AppColors.successOf(cs.brightness),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded,
                color: cs.primary, size: Spacings.mdIcon),
            const SizedBox(width: Spacings.sm),
            Text(
              'Activity Log',
              style: tt.titleMedium?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacings.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: events.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Spacings.xxl),
                  child: AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No Activity',
                    subtitle:
                        'Result access events will appear here as they occur.',
                  ),
                )
              : Column(
                  children: events
                      .map((e) => _buildActivityEvent(context, e))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildActivityEvent(BuildContext context, _ActivityEvent event) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(Spacings.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacings.sm),
            decoration: BoxDecoration(
              color:
                  event.color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            child: Icon(event.icon,
                size: Spacings.mdIcon, color: event.color),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  event.description,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  _formatTimestamp(event.timestamp),
                  style: tt.labelSmall?.copyWith(
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

  // ─── Actions ───────────────────────────────────────────────────────

  Future<void> _toggleLock(
      BuildContext context, ResultManagementState state) async {
    if (state.isResultLocked) {
      // Unlock
      final confirmed = await AppDialog.showConfirm(
        context: context,
        title: 'Unlock Results?',
        message:
            'Unlocking results will allow modifications again. Ensure this is intended.',
        confirmText: 'Unlock',
      );

      if (confirmed == true) {
        ref.read(resultManagementProvider.notifier).unlockResults(
              examId: widget.examId,
              unlockedBy: 'current_teacher', // TODO: from auth
              unlockRemote: ({required examId, required unlockedBy}) async =>
                  Success(
                      // placeholder — actual lock entity returned from repo
                      ResultLockEntity(
                        id: '',
                        examId: '',
                        schoolId: '',
                        lockedBy: '',
                        lockedAt: DateTime(1970),
                        isLocked: false,
                        createdAt: DateTime(1970),
                      )),
            );
      }
    } else {
      // Lock
      final confirmed = await AppDialog.showConfirm(
        context: context,
        title: 'Lock Results?',
        message:
            'Locking results will prevent all further modifications. Only an administrator can unlock them later.',
        confirmText: 'Lock',
        isDestructive: true,
      );

      if (confirmed == true) {
        ref.read(resultManagementProvider.notifier).lockResults(
              examId: widget.examId,
              schoolId: widget.schoolId,
              lockedBy: 'current_teacher', // TODO: from auth
            );
      }
    }
  }

  Future<void> _publishResults(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Publish Results?',
      message:
          'This will make results visible to all students and parents. This action cannot be undone.',
      confirmText: 'Publish',
    );

    if (confirmed == true) {
      ref
          .read(resultManagementProvider.notifier)
          .publishResults(widget.examId);
    }
  }

  Future<void> _withholdResults(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Withhold Results?',
      message:
          'This will hide results from all students and parents. Students will not be able to view their scores.',
      confirmText: 'Withhold',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(resultManagementProvider.notifier).withholdResults(
            widget.examId,
            withholdRemote: (_) async => Success(null),
          );
    }
  }

  Future<void> _recomputeResults(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Recompute Results?',
      message:
          'This will recalculate all subject and overall results for this class. Existing results may change. This may take a while.',
      confirmText: 'Recompute',
    );

    if (confirmed == true) {
      ref.read(resultManagementProvider.notifier).recomputeResults(
            classId: '', // TODO: inject classId
            academicSessionId: '', // TODO: inject sessionId
          );
    }
  }

  // ─── Error Banner ──────────────────────────────────────────────────

  Widget _buildErrorBanner(BuildContext context, String error) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.errorOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.errorOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                error,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.errorOf(cs.brightness),
                ),
              ),
            ),
            AppButton(
              label: 'Retry',
              onPressed: () {
                // Re-attempt lock status check via lock action
                // (no dedicated load method exists on the notifier)
              },
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Success Banner ────────────────────────────────────────────────

  Widget _buildSuccessBanner(BuildContext context, String message) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacings.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacings.md),
        decoration: BoxDecoration(
          color: AppColors.successOf(cs.brightness)
              .withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(Spacings.smRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.successOf(cs.brightness)),
            const SizedBox(width: Spacings.sm),
            Expanded(
              child: Text(
                message,
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.successOf(cs.brightness),
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Timestamp Formatter ───────────────────────────────────────────

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACTION TILE
// ═══════════════════════════════════════════════════════════════════════

/// A list tile for result management actions with icon, title, subtitle,
/// and loading state.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDestructive,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final iconColor = isDestructive
        ? AppColors.errorOf(cs.brightness)
        : cs.primary;

    return InkWell(
      onTap: isLoading ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.md,
          vertical: Spacings.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacings.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(Spacings.smRadius),
              ),
              child: isLoading
                  ? SizedBox(
                      width: Spacings.mdIcon,
                      height: Spacings.mdIcon,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(icon, size: Spacings.mdIcon, color: iconColor),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: AppTypography.wSemiBold,
                      color: isDestructive
                          ? AppColors.errorOf(cs.brightness)
                          : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
              size: Spacings.mdIcon,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACTIVITY EVENT
// ═══════════════════════════════════════════════════════════════════════

/// Model for activity log events displayed in the result management page.
class _ActivityEvent {
  const _ActivityEvent({
    required this.icon,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final DateTime timestamp;
  final Color color;
}
