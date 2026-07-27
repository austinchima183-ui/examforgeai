import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_slide.dart';

// ═══════════════════════════════════════════════════════════════════════
// ONBOARDING SLIDE DATA
// ═══════════════════════════════════════════════════════════════════════

const List<OnboardingData> _onboardingSlides = [
  OnboardingData(
    icon: Icons.auto_awesome_rounded,
    title: 'AI-Powered Question Generation',
    description:
        'Create exam questions instantly with AI assistance. Generate questions across any subject and difficulty level in seconds.',
    gradient: AppColors.brandGradient,
  ),
  OnboardingData(
    icon: Icons.library_books_rounded,
    title: 'Comprehensive Question Bank',
    description:
        'Build and manage question banks for any subject. Organize, categorize, and reuse questions across multiple exams effortlessly.',
    gradient: AppColors.coolGradient,
  ),
  OnboardingData(
    icon: Icons.computer_rounded,
    title: 'Smart CBT Examinations',
    description:
        'Conduct secure computer-based tests with automatic grading, real-time monitoring, and detailed performance analytics.',
    gradient: AppColors.warmGradient,
  ),
];

// ═══════════════════════════════════════════════════════════════════════
// ONBOARDING PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Professional onboarding page with animated slides, page indicators,
/// and navigation controls.
///
/// Walks the user through three feature highlights before marking
/// onboarding as complete and navigating to the dashboard.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _buttonAnimationController;
  late final Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(onboardingProvider.notifier).goToPage(index);
    // Animate the button when reaching the last page
    if (index == _onboardingSlides.length - 1) {
      _buttonAnimationController.forward();
    }
  }

  void _handleNext() {
    final state = ref.read(onboardingProvider);
    if (state.isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleSkip() {
    ref.read(onboardingProvider.notifier).skip();
    _navigateToDashboard();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).complete();
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final onboardingState = ref.watch(onboardingProvider);
    final isLastPage = onboardingState.isLastPage;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip Button ──────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Spacings.md,
                  right: Spacings.lg,
                ),
                child: TextButton(
                  onPressed: isLastPage ? null : _handleSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacings.lg,
                      vertical: Spacings.sm,
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: tt.labelLarge?.copyWith(
                      color: isLastPage
                          ? cs.onSurfaceVariant.withValues(alpha: 0.38)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // ── Page Content ─────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingSlides.length,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return OnboardingSlide(
                    data: _onboardingSlides[index],
                    isActive: onboardingState.currentPage == index,
                  );
                },
              ),
            ),

            // ── Page Indicator Dots ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacings.xl),
              child: _PageIndicator(
                pageCount: _onboardingSlides.length,
                currentPage: onboardingState.currentPage,
                activeColor: cs.primary,
                inactiveColor: cs.outlineVariant,
              ),
            ),

            // ── Bottom Action Button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacings.xl,
              ),
              child: AnimatedBuilder(
                animation: _buttonScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _buttonScaleAnimation.value,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: child,
                      );
                    },
                    child: isLastPage
                        ? FilledButton(
                            key: const ValueKey('get_started'),
                            onPressed: onboardingState.isCompleting
                                ? null
                                : _completeOnboarding,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Spacings.lgRadius,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: onboardingState.isCompleting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: AppTypography.button.copyWith(
                                          color: cs.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: Spacings.sm),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: Spacings.mdIcon,
                                        color: cs.onPrimary,
                                      ),
                                    ],
                                  ),
                          )
                        : FilledButton(
                            key: const ValueKey('next'),
                            onPressed: _handleNext,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Spacings.lgRadius,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Next',
                              style: AppTypography.button.copyWith(
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacings.xxl),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PAGE INDICATOR
// ═══════════════════════════════════════════════════════════════════════

/// Animated page indicator dots for the onboarding PageView.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentPage,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int pageCount;
  final int currentPage;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: Spacings.xs),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(Spacings.smRadius),
          ),
        );
      }),
    );
  }
}
