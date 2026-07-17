import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_guards.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_loading.dart';

/// Dashboard redirector that navigates the user to the correct
/// role-specific dashboard based on their stored role.
///
/// This widget is displayed at the [RouteNames.dashboard] path. It
/// reads the user's role from [currentRoleProvider] and redirects
/// using [GoRouter.go] to the appropriate sub-route.
///
/// If the role cannot be determined (e.g. still loading), a loading
/// indicator is shown. If the role is null after loading completes,
/// the user is redirected to the login page as a safety measure.
class DashboardRedirector extends ConsumerStatefulWidget {
  const DashboardRedirector({super.key});

  @override
  ConsumerState<DashboardRedirector> createState() =>
      _DashboardRedirectorState();
}

class _DashboardRedirectorState extends ConsumerState<DashboardRedirector> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return roleAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacings.lg),
                  decoration: BoxDecoration(
                    color: AppColors.errorOf(
                        context.colorScheme.brightness).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: Spacings.xlIcon,
                    color: AppColors.errorOf(context.colorScheme.brightness),
                  ),
                ),
                const SizedBox(height: Spacings.xl),
                Text(
                  'Failed to load user role',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: context.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacings.sm),
                Text(
                  '$error',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xl),
                FilledButton.tonal(
                  onPressed: () {
                    if (!isAuthenticated) {
                      context.go(RouteNames.login);
                    } else {
                      // Retry by re-reading the role
                      ref.invalidate(userRoleProvider);
                    }
                  },
                  child: Text(
                    isAuthenticated ? 'Retry' : 'Back to Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (roleString) {
        final role = UserRole.fromString(roleString);

        // Schedule the redirect for after the current build frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hasNavigated || !mounted) return;

          if (role != null) {
            _hasNavigated = true;
            context.go(role.dashboardRoute);
          } else {
            // Fallback: no recognizable role, send to login.
            _hasNavigated = true;
            context.go(RouteNames.login);
          }
        });

        // Show loading while the redirect is being processed.
        return const Scaffold(
          body: Center(
            child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
          ),
        );
      },
    );
  }
}
