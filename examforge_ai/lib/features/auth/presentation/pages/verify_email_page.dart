import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/utils/input_validator.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

/// Email verification page — shown after registration to prompt the
/// user to verify their email address.
///
/// Features:
/// - Email display
/// - Resend verification button with cooldown timer
/// - Verification code input (OTP style)
/// - Verify button
/// - Success animation
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage>
    with TickerProviderStateMixin {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  late AnimationController _successController;

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _successController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendVerification() async {
    final authState = ref.read(authProvider);
    final email = authState.user?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address found.')),
      );
      return;
    }

    await ref.read(authProvider.notifier).resendVerification(email: email);

    if (!mounted) return;
    _startCooldown();

    final newState = ref.read(authProvider);
    if (newState.emailVerificationSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email resent!')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    final validationError = InputValidator.validateOTP(otp);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    await ref.read(authProvider.notifier).verifyEmail(token: otp);

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.emailVerified) {
      await _successController.forward();
      if (!mounted) return;

      // Navigate to the dashboard after a brief delay.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.go(RouteNames.dashboard);
        }
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits are entered.
    if (_otpValue.length == 6) {
      _verifyOtp();
    }
  }

  void _onOtpBackspace(int index, String value) {
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final authState = ref.watch(authProvider);

    if (authState.emailVerified) {
      return _buildSuccessView(cs, tt);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ─────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 44,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: Spacings.xl),
                  Text(
                    'Verify Your Email',
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: AppTypography.wBold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacings.md),
                  Text(
                    'We\'ve sent a verification code to\n${authState.user?.email ?? 'your email address'}',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: Spacings.xxl),

                  // ── Error Banner ───────────────────────────────────
                  if (authState.error != null) ...[
                    _buildErrorBanner(cs, authState.error!),
                    const SizedBox(height: Spacings.lg),
                  ],

                  // ── OTP Input ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return _buildOtpField(
                        index: index,
                        cs: cs,
                      );
                    }),
                  ),

                  const SizedBox(height: Spacings.xxl),

                  // ── Verify Button ──────────────────────────────────
                  AppButton(
                    label: 'Verify Email',
                    onPressed: _verifyOtp,
                    variant: AppButtonVariant.elevated,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: Spacings.xl),

                  // ── Resend Verification ────────────────────────────
                  _cooldownSeconds > 0
                      ? Text(
                          'Resend code in ${_cooldownSeconds}s',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : TextButton(
                          onPressed: _resendVerification,
                          child: Text(
                            'Resend Verification Code',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),

                  const SizedBox(height: Spacings.lg),

                  // ── Back to Login ──────────────────────────────────
                  TextButton(
                    onPressed: () => context.go(RouteNames.login),
                    child: Text(
                      'Back to Login',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField({
    required int index,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 48,
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: AppTypography.headlineMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(color: cs.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(color: cs.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(color: cs.error),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: Spacings.md),
          ),
          onChanged: (value) => _onOtpChanged(index, value),
          onFieldSubmitted: (_) => _verifyOtp(),
        ),
      ),
    );
  }

  Widget _buildSuccessView(ColorScheme cs, TextTheme tt) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacings.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Success Animation ────────────────────────────────
                ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _successController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 60,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: Spacings.xxl),
                Text(
                  'Email Verified!',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: AppTypography.wBold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacings.md),
                Text(
                  'Your email has been verified successfully.\nRedirecting to dashboard...',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ColorScheme cs, String error) {
    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: Spacings.mdIcon),
          const SizedBox(width: Spacings.sm),
          Expanded(
            child: Text(
              error,
              style: context.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: Spacings.smIcon, color: cs.error),
            onPressed: () => ref.read(authProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
