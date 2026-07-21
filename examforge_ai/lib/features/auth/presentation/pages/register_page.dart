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
import '../widgets/password_strength_indicator.dart';
import '../../../../config/dependency_injection.dart';


/// Registration page for creating a new account.
///
/// Features:
/// - Full name field
/// - Email field with validation
/// - School code field (optional, for joining a school)
/// - Password field with strength indicator
/// - Confirm password field
/// - Terms and conditions checkbox
/// - Register button with loading state
/// - Login link
///
/// SECURITY: All new accounts register as 'student' by default.
/// Role elevation (to teacher/schoolAdmin) must happen through a
/// separate server-side flow (invite codes, admin approval),
/// not self-service registration.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the terms and conditions')),
      );
      return;
    }

    // SECURITY: Role is always 'student' for self-service registration.
    // Role elevation happens via server-side invite codes / admin approval.
    final schoolCode = _schoolCodeController.text.trim();

    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: 'student',
          schoolId: schoolCode.isNotEmpty ? schoolCode : null,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      if (authState.emailVerificationSent) {
        context.go(RouteNames.verifyEmail);
      } else {
        context.go(RouteNames.dashboard);
      }
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
                    _buildHeader(cs, tt),

                    const SizedBox(height: Spacings.xxl),

                    // ── Error Banner ───────────────────────────────────
                    if (authState.error != null) ...[
                      _buildErrorBanner(cs, authState.error!),
                      const SizedBox(height: Spacings.lg),
                    ],

                    // ── Full Name ──────────────────────────────────────
                    AppTextField(
                      label: 'Full Name',
                      hint: 'John Doe',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: Spacings.lg),

                    // ── Email ──────────────────────────────────────────
                    AppTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      autofillHints: const [AutofillHints.email],
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

                    const SizedBox(height: Spacings.lg),

                    // ── School Code (always visible, optional) ──────────
                    AppTextField(
                      label: 'School Code',
                      hint: 'e.g. SCH001 (optional)',
                      controller: _schoolCodeController,
                      prefixIcon: Icons.domain_outlined,
                      textInputAction: TextInputAction.next,
                      isRequired: false,
                      inputFormatters: [
                        _UpperCaseTextFormatter(),
                      ],
                      validator: (value) {
                        // School code is optional, but if provided it must be valid
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[A-Z0-9]{4,12}$')
                              .hasMatch(value.trim().toUpperCase())) {
                            return 'School code must be 4-12 uppercase alphanumeric characters';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: Spacings.lg),

                    // ── Password ───────────────────────────────────────
                    AppPasswordField(
                      label: 'Password',
                      controller: _passwordController,
                      isRequired: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: Spacings.sm),

                    // ── Password Strength Indicator ────────────────────
                    PasswordStrengthIndicator(
                      password: _passwordController.text,
                    ),

                    const SizedBox(height: Spacings.lg),

                    // ── Confirm Password ──────────────────────────────
                    AppPasswordField(
                      label: 'Confirm Password',
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

                    const SizedBox(height: Spacings.lg),

                    // ── Terms and Conditions ───────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(
                                  () => _agreedToTerms = value ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: Spacings.sm),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _agreedToTerms = !_agreedToTerms),
                            child: RichText(
                              text: TextSpan(
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: AppTypography.wSemiBold,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: AppTypography.wSemiBold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Spacings.xxl),

                    // ── Register Button ────────────────────────────────
                    AppButton(
                      label: 'Create Account',
                      onPressed: _submit,
                      variant: AppButtonVariant.elevated,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      isLoading: authState.isLoading,
                      isDisabled: !_agreedToTerms,
                    ),

                    const SizedBox(height: Spacings.xl),

                    // ── Login Link ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(RouteNames.login),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign In',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE BUILDERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHeader(ColorScheme cs, TextTheme tt) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(Spacings.lgRadius),
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: Spacings.lg),
        Text(
          'Create Account',
          style: tt.headlineMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          'Join ExamForge AI and start your journey',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
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

/// Text input formatter that converts input to uppercase.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
