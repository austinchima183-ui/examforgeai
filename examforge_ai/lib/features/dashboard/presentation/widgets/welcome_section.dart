import 'package:flutter/material.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../routing/route_guards.dart';

// ═══════════════════════════════════════════════════════════════════════
// WELCOME SECTION
// ═══════════════════════════════════════════════════════════════════════

/// A welcome banner displayed at the top of every dashboard with:
/// - Greeting based on time of day (Good morning / afternoon / evening)
/// - User name
/// - User role badge
/// - Current date
/// - Subtle gradient background
/// - Animated entrance
///
/// ```dart
/// WelcomeSection(userName: 'Dr. Smith', role: UserRole.teacher)
/// ```
class WelcomeSection extends StatefulWidget {
  const WelcomeSection({
    required this.userName,
    this.role,
    super.key,
  });

  /// Display name of the current user.
  final String userName;

  /// User role for the role badge.
  final UserRole? role;

  @override
  State<WelcomeSection> createState() => _WelcomeSectionState();
}

class _WelcomeSectionState extends State<WelcomeSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _formattedDate {
    final now = DateTime.now();
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday',
    ];
    return '${weekdays[now.weekday]}, ${months[now.month]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacings.xl),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer.withValues(alpha: 0.4),
                      cs.tertiaryContainer.withValues(alpha: 0.3),
                    ],
                  )
                : AppColors.brandGradient,
            borderRadius: BorderRadius.circular(Spacings.lgRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Greeting & Date Row ────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_greeting,',
                          style: tt.titleMedium?.copyWith(
                            color: isDark
                                ? cs.onSurface
                                : Colors.white.withValues(alpha: 0.85),
                            fontWeight: AppTypography.wMedium,
                          ),
                        ),
                        const SizedBox(height: Spacings.xs),
                        Text(
                          widget.userName,
                          style: tt.headlineSmall?.copyWith(
                            color: isDark
                                ? cs.onSurface
                                : Colors.white,
                            fontWeight: AppTypography.wBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ── Role Badge ────────────────────────────────────
                  if (widget.role != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.md,
                        vertical: Spacings.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.primaryContainer.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(Spacings.fullRadius),
                        border: Border.all(
                          color: isDark
                              ? cs.outline.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _roleIcon(widget.role!),
                            size: Spacings.smIcon,
                            color: isDark
                                ? cs.onSurface
                                : Colors.white,
                          ),
                          const SizedBox(width: Spacings.xs),
                          Text(
                            widget.role!.label,
                            style: tt.labelSmall?.copyWith(
                              color: isDark
                                  ? cs.onSurface
                                  : Colors.white,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacings.md),
              // ── Date ──────────────────────────────────────────────
              Text(
                _formattedDate,
                style: tt.bodySmall?.copyWith(
                  color: isDark
                      ? cs.onSurfaceVariant
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.teacher => Icons.school_outlined,
      UserRole.student => Icons.menu_book_outlined,
      UserRole.schoolAdmin => Icons.admin_panel_settings_outlined,
      UserRole.superAdmin => Icons.shield_outlined,
    };
  }
}
