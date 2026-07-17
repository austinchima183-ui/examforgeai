import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';

/// A grid of quick-action cards for the Teacher Workspace dashboard.
///
/// Displays eight primary workspace actions in a responsive 4-column grid,
/// each navigating to its respective module route. Follows Material 3 design
/// with the Indigo #4F46E5 seed color.
class WorkspaceQuickActions extends StatelessWidget {
  const WorkspaceQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      QuickActionData(
        icon: Icons.auto_stories_rounded,
        label: 'Lesson Plan',
        route: RouteNames.lessonPlanCreate,
        color: theme.colorScheme.primary,
      ),
      QuickActionData(
        icon: Icons.calendar_month_rounded,
        label: 'Scheme of Work',
        route: RouteNames.schemeOfWorkCreate,
        color: theme.colorScheme.tertiary,
      ),
      QuickActionData(
        icon: Icons.assignment_rounded,
        label: 'Worksheet',
        route: RouteNames.worksheetCreate,
        color: theme.colorScheme.secondary,
      ),
      QuickActionData(
        icon: Icons.task_rounded,
        label: 'Assignment',
        route: RouteNames.assignmentCreate,
        color: Colors.orange,
      ),
      QuickActionData(
        icon: Icons.rate_review_rounded,
        label: 'Comments',
        route: RouteNames.reportCommentGenerator,
        color: Colors.teal,
      ),
      QuickActionData(
        icon: Icons.psychology_rounded,
        label: 'AI Assistant',
        route: RouteNames.contentAssistant,
        color: Colors.purple,
      ),
      QuickActionData(
        icon: Icons.folder_rounded,
        label: 'Resources',
        route: RouteNames.teachingResources,
        color: Colors.blueGrey,
      ),
      QuickActionData(
        icon: Icons.calendar_today_rounded,
        label: 'Planner',
        route: RouteNames.calendarPlanner,
        color: Colors.indigo,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        mainAxisSpacing: Spacings.md,
        crossAxisSpacing: Spacings.md,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionCard(action: action);
      },
    );
  }
}

/// A single quick-action card with an icon and label.
class _QuickActionCard extends StatelessWidget {
  final QuickActionData action;

  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: Spacings.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: Spacings.borderRadiusMd,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: Spacings.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacings.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: Spacings.borderRadiusMd,
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: Spacings.sm),
              Text(
                action.label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for a single quick action entry.
class QuickActionData {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const QuickActionData({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
