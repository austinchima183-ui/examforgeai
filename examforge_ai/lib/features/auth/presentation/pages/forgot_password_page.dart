import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../../config/dependency_injection.dart';


/// Forgot password page — sends a password-reset email.
///
/// Features:
/// - Email field with validation
/// - Send reset link button
/// - Back to login link
/// - Success state showing "check your email"
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).forgotPassword(
          email: _emailController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final authState = ref.watch(authProvider);

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
              child: authState.passwordResetSent
                  ? _buildSuccessView(cs, tt)
                  : _buildFormView(cs, tt, authState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ColorScheme cs, TextTheme tt, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(Spacings.lgRadius),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 36,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: Spacings.xl),
          Text(
            'Reset Password',
            style: tt.headlineMedium?.copyWith(
              fontWeight: AppTypography.wBold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.sm),
          Text(
            'Enter your email and we\'ll send you a link to reset your password.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacings.xxl),

          // ── Error Banner ───────────────────────────────────────────
          if (authState.error != null) ...[
            _buildErrorBanner(cs, authState.error!),
            const SizedBox(height: Spacings.lg),
          ],

          // ── Email Field ────────────────────────────────────────────
          AppTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            isRequired: true,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                  .hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: Spacings.xxl),

          // ── Send Reset Link Button ─────────────────────────────────
          AppButton(
            label: 'Send Reset Link',
            onPressed: _submit,
            variant: AppButtonVariant.elevated,
            size: AppButtonSize.large,
            fullWidth: true,
            isLoading: authState.isLoading,
          ),

          const SizedBox(height: Spacings.xl),

          // ── Back to Login ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: Spacings.smIcon, color: cs.primary),
              const SizedBox(width: Spacings.xs),
              TextButton(
                onPressed: () => context.go(RouteNames.login),
                child: Text(
                  'Back to Login',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(ColorScheme cs, TextTheme tt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Success Icon ────────────────────────────────────────────
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 44,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: Spacings.xl),
        Text(
          'Check Your Email',
          style: tt.headlineMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.md),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          'Please check your inbox and follow the instructions to reset your password.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.xxl),
        AppButton(
          label: 'Back to Login',
          onPressed: () => context.go(RouteNames.login),
          variant: AppButtonVariant.elevated,
          size: AppButtonSize.large,
          fullWidth: true,
        ),
        const SizedBox(height: Spacings.lg),
        TextButton(
          onPressed: _submit,
          child: Text(
            'Didn\'t receive the email? Resend',
            style: tt.bodySmall?.copyWith(
              color: cs.primary,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
      ],
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
