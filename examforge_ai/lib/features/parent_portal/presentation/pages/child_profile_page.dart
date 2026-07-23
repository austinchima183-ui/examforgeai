import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_app_bar.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/parent_portal_entities.dart';
import '../providers/child_profile_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// CHILD PROFILE PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Detailed child profile page for the Parent Portal.
///
/// Displays comprehensive information about a specific child including:
/// - Profile header with avatar, name, admission number, class & stream
/// - Student information card (admission, class, subjects, class teacher)
/// - Emergency information card (if available)
/// - Quick actions row (Results, Attendance, Assignments, Contact Teacher)
/// - Teachers card (list of subject teachers)
///
/// Receives [studentId] as a route parameter and loads the profile
/// using [childProfileProvider].
class ChildProfilePage extends ConsumerStatefulWidget {
  const ChildProfilePage({
    super.key,
    required this.studentId,
  });

  /// Unique identifier of the student whose profile is displayed.
  final String studentId;

  @override
  ConsumerState<ChildProfilePage> createState() => _State();
}

class _State extends ConsumerState<ChildProfilePage> {
  // ─── Lifecycle ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(childProfileProvider.notifier)
          .loadProfile(widget.studentId);
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(childProfileProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: profileState.profile?.displayName ?? 'Child Profile',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, profileState),
    );
  }

  // ─── Body Router ────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, ChildProfileState state) {
    // Loading state
    if (state.isLoading && state.profile == null) {
      return _buildShimmerLoading(context);
    }

    // Error state
    if (state.error != null && state.profile == null) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref
            .read(childProfileProvider.notifier)
            .loadProfile(widget.studentId),
      );
    }

    // Empty state
    final profile = state.profile;
    if (profile == null) {
      return AppEmptyState.noData(
        title: 'Profile Not Found',
        subtitle:
            'The child profile could not be loaded. Please try again.',
        actionLabel: 'Retry',
        onAction: () => ref
            .read(childProfileProvider.notifier)
            .loadProfile(widget.studentId),
      );
    }

    // Success — render profile
    return RefreshIndicator(
      onRefresh: () => ref
          .read(childProfileProvider.notifier)
          .refreshProfile(widget.studentId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacings.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Header ──────────────────────────────────────
            _buildProfileHeader(context, profile),

            const SizedBox(height: Spacings.xl),

            // ─── Quick Actions Row ──────────────────────────────────
            _buildQuickActionsRow(context, profile),

            const SizedBox(height: Spacings.xl),

            // ─── Student Information Card ───────────────────────────
            _buildStudentInfoCard(context, profile),

            const SizedBox(height: Spacings.lg),

            // ─── Emergency Information Card ─────────────────────────
            // TODO: Add when emergency info is available in entity

            // ─── Teachers Card ──────────────────────────────────────
            // TODO: Add when teachers info is available in entity

            const SizedBox(height: Spacings.lg),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: AppLoadingShimmer(
        child: Column(
          children: [
            const SizedBox(height: Spacings.xxl),
            // Avatar shimmer
            const Center(
              child: AppLoadingShimmer.box(
                width: 80,
                height: 80,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: Spacings.lg),
            // Name shimmer
            const Center(
              child: AppLoadingShimmer.box(
                width: 180,
                height: 20,
                borderRadius: Spacings.borderRadiusSm,
              ),
            ),
            const SizedBox(height: Spacings.sm),
            const Center(
              child: AppLoadingShimmer.box(
                width: 140,
                height: 14,
                borderRadius: Spacings.borderRadiusSm,
              ),
            ),
            const SizedBox(height: Spacings.xl),
            // Quick actions shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (_) => const Column(
                    children: [
                      AppLoadingShimmer.box(
                        width: 48,
                        height: 48,
                        shape: BoxShape.circle,
                      ),
                      SizedBox(height: Spacings.sm),
                      AppLoadingShimmer.box(
                        width: 60,
                        height: 12,
                        borderRadius: Spacings.borderRadiusSm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacings.xl),
            // Info card shimmer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacings.lg),
              child: AppLoadingShimmer.box(
                height: 200,
                borderRadius: Spacings.borderRadiusLg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(
    BuildContext context,
    ChildProfileEntity profile,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final initial = profile.firstName.isNotEmpty
        ? profile.firstName[0].toUpperCase()
        : '?';

    return Center(
      child: Column(
        children: [
          const SizedBox(height: Spacings.lg),
          // Avatar circle
          CircleAvatar(
            radius: 44,
            backgroundColor: cs.primaryContainer,
            child: Text(
              initial,
              style: tt.headlineMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: AppTypography.wBold,
              ),
            ),
          ),
          const SizedBox(height: Spacings.md),
          // Student name
          Text(
            profile.displayName,
            style: tt.headlineSmall?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: Spacings.xs),
          // Admission number
          if (profile.admissionNumber != null)
            Text(
              'Adm: ${profile.admissionNumber}',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: Spacings.xs),
          // Class & stream
          if (profile.className != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.md,
                vertical: Spacings.xs,
              ),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: Spacings.borderRadiusSm,
              ),
              child: Text(
                profile.className!,
                style: tt.labelMedium?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: AppTypography.wMedium,
                ),
              ),
            ),
          const SizedBox(height: Spacings.sm),
          // Relationship badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: Spacings.borderRadiusSm,
            ),
            child: Text(
              profile.relationship,
              style: tt.labelSmall?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK ACTIONS ROW
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickActionsRow(
    BuildContext context,
    ChildProfileEntity profile,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final studentId = profile.studentId;

    final actions = [
      _QuickAction(
        label: 'Results',
        icon: Icons.bar_chart_outlined,
        color: AppColors.successOf(cs.brightness),
        onTap: () => context.go(
          '${RouteNames.parentPortal}/child/$studentId/performance',
        ),
      ),
      _QuickAction(
        label: 'Attendance',
        icon: Icons.calendar_today_outlined,
        color: AppColors.infoOf(cs.brightness),
        onTap: () => context.go(
          '${RouteNames.parentPortal}/child/$studentId/attendance',
        ),
      ),
      _QuickAction(
        label: 'Assignments',
        icon: Icons.assignment_outlined,
        color: AppColors.warningOf(cs.brightness),
        onTap: () => context.go(
          '${RouteNames.parentPortal}/child/$studentId/assignments',
        ),
      ),
      _QuickAction(
        label: 'Contact',
        icon: Icons.chat_outlined,
        color: cs.primary,
        onTap: () {
          // TODO: Navigate to messaging with class teacher
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((action) {
          return InkWell(
            onTap: action.onTap,
            borderRadius: Spacings.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.all(Spacings.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action.icon,
                      color: action.color,
                      size: Spacings.mdIcon,
                    ),
                  ),
                  const SizedBox(height: Spacings.xs),
                  Text(
                    action.label,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: AppTypography.wMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDENT INFORMATION CARD
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStudentInfoCard(
    BuildContext context,
    ChildProfileEntity profile,
  ) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacings.lg),
      child: Card(
        elevation: Spacings.elevationSm,
        shape: const RoundedRectangleBorder(
          borderRadius: Spacings.borderRadiusLg,
        ),
        child: Padding(
          padding: Spacings.paddingCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Information',
                style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.md),
              const Divider(height: 1),
              const SizedBox(height: Spacings.md),
              // Admission Number
              _buildInfoRow(
                context,
                icon: Icons.badge_outlined,
                label: 'Admission Number',
                value: profile.admissionNumber ?? '—',
              ),
              const SizedBox(height: Spacings.md),
              // Class
              _buildInfoRow(
                context,
                icon: Icons.class_outlined,
                label: 'Class',
                value: profile.className ?? '—',
              ),
              const SizedBox(height: Spacings.md),
              // Relationship
              _buildInfoRow(
                context,
                icon: Icons.family_restroom_outlined,
                label: 'Relationship',
                value: profile.relationship,
              ),
              const SizedBox(height: Spacings.md),
              // Primary Contact
              _buildInfoRow(
                context,
                icon: Icons.contact_phone_outlined,
                label: 'Primary Contact',
                value: profile.isPrimaryContact ? 'Yes' : 'No',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
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
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: AppTypography.wMedium,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════

/// A data holder for a single quick-action entry on the profile page.
class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  /// Label text displayed below the icon.
  final String label;

  /// Icon displayed in the action circle.
  final IconData icon;

  /// Tint colour for the icon and circle background.
  final Color color;

  /// Callback when the action is tapped.
  final VoidCallback onTap;
}
