import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../widgets/password_strength_indicator.dart';


/// Reset password page — the deep-link target from the password-reset
/// email. Allows the user to enter and confirm a new password.
///
/// Features:
/// - New password field with strength indicator
/// - Confirm new password field
/// - Password strength indicator
/// - Reset button with loading state
/// - Success state redirecting to login
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() =>
      _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Supabase SDK uses the session from the deep link; token is handled
    // internally by the SDK.
    await ref.read(authProvider.notifier).resetPassword(
          token: '',
          newPassword: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.passwordResetComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully!')),
      );
      context.go(RouteNames.login);
    }
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(Spacings.lgRadius),
                      ),
                      child: Icon(
                        Icons.password_rounded,
                        size: 36,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: Spacings.xl),
                    Text(
                      'Set New Password',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: AppTypography.wBold,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacings.sm),
                    Text(
                      'Create a new password for your account. Make sure it\'s strong and memorable.',
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

                    // ── New Password Field ─────────────────────────────
                    AppPasswordField(
                      label: 'New Password',
                      controller: _passwordController,
                      isRequired: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return 'Must contain at least one lowercase letter';
                        }
                        if (!RegExp(r'\d').hasMatch(value)) {
                          return 'Must contain at least one digit';
                        }
                        if (!RegExp(
                                r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]',)
                            .hasMatch(value)) {
                          return 'Must contain at least one special character';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: Spacings.sm),

                    // ── Password Strength Indicator ────────────────────
                    PasswordStrengthIndicator(
                      password: _passwordController.text,
                    ),

                    const SizedBox(height: Spacings.lg),

                    // ── Confirm New Password Field ─────────────────────
                    AppPasswordField(
                      label: 'Confirm New Password',
                      controller: _confirmPasswordController,
                      isRequired: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: Spacings.xxl),

                    // ── Reset Button ───────────────────────────────────
                    AppButton(
                      label: 'Reset Password',
                      onPressed: _submit,
                      variant: AppButtonVariant.elevated,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      isLoading: authState.isLoading,
                    ),

                    const SizedBox(height: Spacings.lg),

                    // ── Back to Login ──────────────────────────────────
                    TextButton(
                      onPressed: () => context.go(RouteNames.login),
                      child: Text(
                        'Back to Login',
                        style: tt.bodyMedium?.copyWith(
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
