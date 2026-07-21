import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_dialog.dart';
import '../../../../../routing/route_names.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/parent_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// PARENT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Parent detail page showing profile, linked children, and contact info.
/// Supports adding/linking children and unlinking with confirmation.
class ParentDetailPage extends ConsumerWidget {
  const ParentDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: In a full implementation, we'd watch a parentDetailProvider.
    // For now, we use parentListProvider and filter by userId.
    final state = ref.watch(parentListProvider);
    final parent = state.parents.where((p) => p.userId == userId).firstOrNull;

    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          parent?.fullName ?? 'Parent Details',
          style: tt.titleLarge?.copyWith(
            fontWeight: AppTypography.wSemiBold,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
            onPressed: () {
              // Navigate to edit parent form
            },
            tooltip: 'Edit parent',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
            )
          : state.error != null
              ? AppErrorState.genericError(
                  message: state.error,
                  onRetry: () => ref
                      .read(parentListProvider.notifier)
                      .loadParents('current-school'),
                )
              : parent == null
                  ? const AppEmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Parent Not Found',
                      subtitle:
                          'The requested parent profile could not be loaded.',
                    )
                  : _buildContent(context, parent),
    );
  }

  Widget _buildContent(BuildContext context, ParentProfileEntity parent) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacings.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Profile Header ───────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: parent.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            parent.avatarUrl!,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.family_restroom_rounded,
                              color: AppColors.info,
                              size: Spacings.xlIcon,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.family_restroom_rounded,
                          color: AppColors.info,
                          size: Spacings.xlIcon,
                        ),
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  parent.fullName ?? 'Unknown Parent',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                ),
                if (parent.occupation != null) ...[
                  const SizedBox(height: Spacings.xs),
                  Text(
                    parent.occupation!,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: Spacings.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: parent.isActive
                            ? AppColors.success.withOpacity(isDark ? 0.20 : 0.12)
                            : AppColors.warning.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        parent.isActive ? 'Active' : 'Inactive',
                        style: tt.labelSmall?.copyWith(
                          color: parent.isActive ? AppColors.success : AppColors.warning,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacings.xxl),

          // ─── Contact Information ──────────────────────────────────
          _SectionTitle(title: 'Contact Information'),
          const SizedBox(height: Spacings.sm),
          AppCard(
            child: Column(
              children: [
                if (parent.email != null)
                  _ContactRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: parent.email!,
                  ),
                if (parent.phone != null) ...[
                  if (parent.email != null) const Divider(height: Spacings.lg),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: parent.phone!,
                  ),
                ],
                if (parent.homeAddress != null) ...[
                  if (parent.email != null || parent.phone != null)
                    const Divider(height: Spacings.lg),
                  _ContactRow(
                    icon: Icons.home_outlined,
                    label: 'Home Address',
                    value: parent.homeAddress!,
                  ),
                ],
                if (parent.officeAddress != null) ...[
                  if (parent.email != null ||
                      parent.phone != null ||
                      parent.homeAddress != null)
                    const Divider(height: Spacings.lg),
                  _ContactRow(
                    icon: Icons.business_outlined,
                    label: 'Office Address',
                    value: parent.officeAddress!,
                  ),
                ],
                if (parent.employer != null) ...[
                  if (parent.email != null ||
                      parent.phone != null ||
                      parent.homeAddress != null ||
                      parent.officeAddress != null)
                    const Divider(height: Spacings.lg),
                  _ContactRow(
                    icon: Icons.work_outlined,
                    label: 'Employer',
                    value: parent.employer!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: Spacings.xxl),

          // ─── Linked Children ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(
                  title: 'Children (${parent.children.length})'),
              AppButton(
                label: 'Link Child',
                onPressed: () => _showLinkChildDialog(context),
                variant: AppButtonVariant.tonal,
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
              ),
            ],
          ),
          const SizedBox(height: Spacings.md),

          if (parent.children.isEmpty)
            const AppEmptyState(
              icon: Icons.child_care_outlined,
              title: 'No Children Linked',
              subtitle: 'Link a child to this parent profile.',
            )
          else
            ...parent.children.map((link) => Padding(
                  padding: const EdgeInsets.only(bottom: Spacings.md),
                  child: _ChildCard(
                    link: link,
                    onUnlink: () => _showUnlinkConfirmation(context, link),
                  ),
                )),
        ],
      ),
    );
  }

  void _showLinkChildDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Child'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Student ID or Admission Number',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: Spacings.md),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.people_outline_rounded),
              ),
              items: const [
                DropdownMenuItem(value: 'parent', child: Text('Parent')),
                DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                DropdownMenuItem(value: 'sponsor', child: Text('Sponsor')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: Spacings.md),
            SwitchListTile(
              title: const Text('Primary Contact'),
              value: false,
              onChanged: (_) {},
              activeColor: context.colorScheme.primary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Call link child
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  void _showUnlinkConfirmation(
    BuildContext context,
    ParentStudentLinkEntity link,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Child'),
        content: Text(
          'Are you sure you want to unlink ${link.studentName ?? 'this child'} '
          'from this parent? This can be reversed by linking them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Call unlink
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHILD CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.link,
    this.onUnlink,
  });

  final ParentStudentLinkEntity link;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: () {
        // Navigate to student detail
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: cs.primary,
              size: Spacings.mdIcon,
            ),
          ),
          const SizedBox(width: Spacings.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.studentName ?? 'Unknown Student',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    if (link.studentAdmissionNumber != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(Spacings.smRadius),
                        ),
                        child: Text(
                          link.studentAdmissionNumber!,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.smRadius),
                      ),
                      child: Text(
                        link.relationship.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: AppTypography.wSemiBold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (link.isPrimaryContact) ...[
                      const SizedBox(width: Spacings.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacings.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(Spacings.fullRadius),
                        ),
                        child: Text(
                          'PRIMARY',
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
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.link_off_rounded,
              color: AppColors.error,
              size: Spacings.mdIcon,
            ),
            onPressed: onUnlink,
            tooltip: 'Unlink child',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Text(
      title,
      style: tt.titleSmall?.copyWith(
        fontWeight: AppTypography.wBold,
        color: cs.primary,
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              Text(
                value,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
