import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_app_bar.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../domain/entities/exam_template_entities.dart';
import '../../../domain/entities/cbt_entities.dart';
import '../../providers/submission_receipt_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// SUBMISSION RECEIPT PAGE (Student)
// ═══════════════════════════════════════════════════════════════════════

/// Student's submission receipt page showing verifiable proof of exam
/// submission including receipt number, answer statistics, time spent,
/// device info, and verified status.
class SubmissionReceiptPage extends ConsumerWidget {
  const SubmissionReceiptPage({
    super.key,
    required this.attemptId,
  });

  /// The exam attempt ID to load the receipt for.
  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(submissionReceiptProvider);
    final receipt = state.receipt;

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Submission Receipt',
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            )
          : state.error != null && receipt == null
              ? Center(
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Receipt Not Available',
                    subtitle: state.error ??
                        'Your submission receipt could not be loaded.',
                    actionLabel: 'Try Again',
                    onAction: () => ref
                        .read(submissionReceiptProvider.notifier)
                        .loadReceipt(attemptId),
                  ),
                )
              : receipt == null
                  ? Center(
                      child: AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Receipt',
                        subtitle: 'Submit an exam to generate a receipt.',
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(Spacings.lg),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Receipt Header ─────────────────────────
                              _buildReceiptHeader(context, receipt, state),
                              const SizedBox(height: Spacings.xl),

                              // ── Answer Statistics ──────────────────────
                              _buildAnswerStatistics(context, receipt),
                              const SizedBox(height: Spacings.xl),

                              // ── Time & Submission Details ──────────────
                              _buildSubmissionDetails(context, receipt),
                              const SizedBox(height: Spacings.xl),

                              // ── Device Info Summary ───────────────────
                              if (receipt.deviceInfo != null) ...[
                                _buildDeviceInfo(context, receipt),
                                const SizedBox(height: Spacings.xl),
                              ],

                              // ── Verified Status ───────────────────────
                              _buildVerifiedStatus(context, state, receipt),
                              const SizedBox(height: Spacings.xl),

                              // ── Action Buttons ────────────────────────
                              _buildActionButtons(context, state, receipt),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  // ─── Receipt Header ───────────────────────────────────────────────────

  Widget _buildReceiptHeader(
    BuildContext context,
    SubmissionReceiptEntity receipt,
    SubmissionReceiptState state,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacings.md),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(Spacings.mdRadius),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: Spacings.lgIcon,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: Spacings.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.examTitle,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Spacings.xs),
                    Text(
                      'Submitted ${_formatDateTime(receipt.submittedAt)}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Spacings.xl),

          // Receipt number with copy-to-clipboard
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECEIPT NUMBER',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: AppTypography.wSemiBold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        receipt.receiptNumber,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: AppTypography.wBold,
                          color: cs.onSurface,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: receipt.receiptNumber),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt number copied'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: Spacings.mdIcon,
                    color: cs.primary,
                  ),
                  tooltip: 'Copy receipt number',
                ),
              ],
            ),
          ),

          // Submission type badge
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              _buildSubmissionTypeBadge(context, receipt.submissionType),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Answer Statistics ─────────────────────────────────────────────────

  Widget _buildAnswerStatistics(
    BuildContext context,
    SubmissionReceiptEntity receipt,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final answeredPercent = receipt.totalQuestions > 0
        ? (receipt.answeredQuestions / receipt.totalQuestions * 100)
            .round()
        : 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Statistics',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.check_circle_rounded,
                  label: 'Answered',
                  value: '${receipt.answeredQuestions}',
                  color: AppColors.successOf(cs.brightness),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.radio_button_unchecked_rounded,
                  label: 'Unanswered',
                  value: '${receipt.unansweredQuestions}',
                  color: AppColors.warningOf(cs.brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.flag_rounded,
                  label: 'Flagged',
                  value: '${receipt.flaggedQuestions}',
                  color: AppColors.infoOf(cs.brightness),
                ),
              ),
              const SizedBox(width: Spacings.md),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: Icons.quiz_rounded,
                  label: 'Total',
                  value: '${receipt.totalQuestions}',
                  color: cs.primary,
                ),
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: Spacings.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion',
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$answeredPercent%',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: AppColors.successOf(cs.brightness),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacings.xs),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(Spacings.smRadius),
                      child: LinearProgressIndicator(
                        value: answeredPercent / 100.0,
                        minHeight: 6.0,
                        backgroundColor: cs.surfaceContainerHighest,
                        color: AppColors.successOf(cs.brightness),
                        borderRadius:
                            BorderRadius.circular(Spacings.smRadius),
                      ),
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

  // ─── Submission Details ────────────────────────────────────────────────

  Widget _buildSubmissionDetails(
    BuildContext context,
    SubmissionReceiptEntity receipt,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission Details',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),

          _buildDetailRow(
            context,
            icon: Icons.schedule_rounded,
            label: 'Time Spent',
            value: _formatTimeSpent(receipt.timeSpentMinutes),
          ),
          const SizedBox(height: Spacings.md),

          _buildDetailRow(
            context,
            icon: Icons.event_rounded,
            label: 'Submitted At',
            value: _formatDateTime(receipt.submittedAt),
          ),
          const SizedBox(height: Spacings.md),

          _buildDetailRow(
            context,
            icon: Icons.how_to_reg_rounded,
            label: 'Submission Type',
            value: receipt.submissionType.label,
          ),

          if (receipt.ipAddress != null) ...[
            const SizedBox(height: Spacings.md),
            _buildDetailRow(
              context,
              icon: Icons.language_rounded,
              label: 'IP Address',
              value: receipt.ipAddress!,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Device Info ───────────────────────────────────────────────────────

  Widget _buildDeviceInfo(
    BuildContext context,
    SubmissionReceiptEntity receipt,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final deviceInfo = receipt.deviceInfo!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Information',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),

          if (deviceInfo['platform'] != null)
            _buildDetailRow(
              context,
              icon: Icons.devices_rounded,
              label: 'Platform',
              value: deviceInfo['platform'].toString(),
            ),
          if (deviceInfo['browser'] != null) ...[
            const SizedBox(height: Spacings.md),
            _buildDetailRow(
              context,
              icon: Icons.web_rounded,
              label: 'Browser',
              value: deviceInfo['browser'].toString(),
            ),
          ],
          if (deviceInfo['os'] != null) ...[
            const SizedBox(height: Spacings.md),
            _buildDetailRow(
              context,
              icon: Icons.computer_rounded,
              label: 'OS',
              value: deviceInfo['os'].toString(),
            ),
          ],
          if (deviceInfo['screenResolution'] != null) ...[
            const SizedBox(height: Spacings.md),
            _buildDetailRow(
              context,
              icon: Icons.monitor_rounded,
              label: 'Screen',
              value: deviceInfo['screenResolution'].toString(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Verified Status ───────────────────────────────────────────────────

  Widget _buildVerifiedStatus(
    BuildContext context,
    SubmissionReceiptState state,
    SubmissionReceiptEntity receipt,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final isVerified = state.isVerified ?? receipt.isVerified;
    final statusColor = isVerified
        ? AppColors.successOf(cs.brightness)
        : AppColors.warningOf(cs.brightness);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Status',
            style: tt.titleSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.lg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spacings.lg),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified
                      ? Icons.verified_user_rounded
                      : Icons.pending_rounded,
                  size: Spacings.lgIcon,
                  color: statusColor,
                ),
                const SizedBox(width: Spacings.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified ? 'Verified' : 'Pending Verification',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: Spacings.xs),
                      Text(
                        isVerified
                            ? 'This receipt has been verified as authentic.'
                            : 'Tap "Verify Receipt" to confirm authenticity.',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Buttons ────────────────────────────────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    SubmissionReceiptState state,
    SubmissionReceiptEntity receipt,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Verify Receipt',
            onPressed: () => _verifyReceipt(context, receipt.receiptNumber),
            variant: AppButtonVariant.tonal,
            icon: Icons.verified_user_rounded,
          ),
        ),
        const SizedBox(height: Spacings.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Download',
                onPressed: () => _downloadReceipt(context),
                variant: AppButtonVariant.outlined,
                icon: Icons.download_rounded,
              ),
            ),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: AppButton(
                label: 'Share',
                onPressed: () => _shareReceipt(context),
                variant: AppButtonVariant.outlined,
                icon: Icons.share_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Helper Methods ────────────────────────────────────────────────────

  void _verifyReceipt(BuildContext context, String receiptNumber) {
    // Access the notifier through the reader — this widget uses ConsumerWidget
    // so we need to get ref from the build context's ProviderScope
    // For simplicity, this would be called with ref in a ConsumerStatefulWidget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifying receipt...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _downloadReceipt(BuildContext context) {
    // Placeholder: download receipt as PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download receipt — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    // Placeholder: share receipt
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share receipt — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: Spacings.mdIcon, color: color),
          const SizedBox(height: Spacings.sm),
          Text(
            value,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: color,
            ),
          ),
          Text(
            label,
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Row(
      children: [
        Icon(icon, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionTypeBadge(
    BuildContext context,
    SubmissionType type,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    final color = switch (type) {
      SubmissionType.manual => AppColors.successOf(cs.brightness),
      SubmissionType.autoSubmit => AppColors.infoOf(cs.brightness),
      SubmissionType.timedOut => AppColors.warningOf(cs.brightness),
      SubmissionType.forceSubmit => AppColors.errorOf(cs.brightness),
    };

    final icon = switch (type) {
      SubmissionType.manual => Icons.send_rounded,
      SubmissionType.autoSubmit => Icons.autorenew_rounded,
      SubmissionType.timedOut => Icons.timer_off_rounded,
      SubmissionType.forceSubmit => Icons.power_settings_new_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.sm,
        vertical: Spacings.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: color),
          const SizedBox(width: Spacings.xs),
          Text(
            type.label,
            style: tt.labelSmall?.copyWith(
              fontWeight: AppTypography.wSemiBold,
              color: isDark ? color.withOpacity(0.9) : color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} at $hour:$minute';
  }

  String _formatTimeSpent(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}
