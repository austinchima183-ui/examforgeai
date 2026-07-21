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
import '../providers/auth_form_provider.dart';
import '../../../../config/dependency_injection.dart';


/// Professional login page with email/password authentication.
///
/// Features:
/// - App logo and branding at the top
/// - Email field with validation
/// - Password field with show/hide toggle
/// - Remember me checkbox
/// - Forgot password link
/// - Login button with loading state
/// - Register link
/// - Social login buttons (placeholder)
/// - Responsive layout (centered card on desktop)
/// - Error message display
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      ref
          .read(authFormProvider.notifier)
          .onEmailChanged(_emailController.text);
    });
    _passwordController.addListener(() {
      ref
          .read(authFormProvider.notifier)
          .onPasswordChanged(_passwordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final authState = ref.watch(authProvider);
    final formState = ref.watch(authFormProvider);

    return Scaffold(
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
                    // ── Logo & Branding ────────────────────────────────
                    _buildHeader(cs, tt),

                    const SizedBox(height: Spacings.xxl),

                    // ── Error Banner ───────────────────────────────────
                    if (authState.error != null)
                      _buildErrorBanner(cs, authState.error!),

                    if (authState.error != null)
                      const SizedBox(height: Spacings.lg),

                    // ── Email Field ────────────────────────────────────
                    AppTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      focusNode: _emailFocusNode,
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
                      onFieldSubmitted: (_) {
                        _passwordFocusNode.requestFocus();
                      },
                    ),

                    const SizedBox(height: Spacings.lg),

                    // ── Password Field ─────────────────────────────────
                    AppPasswordField(
                      label: 'Password',
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      isRequired: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: Spacings.md),

                    // ── Remember Me & Forgot Password ──────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: Spacings.sm),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _rememberMe = !_rememberMe),
                              child: Text(
                                'Remember me',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(RouteNames.forgotPassword),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: AppTypography.wSemiBold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Spacings.xl),

                    // ── Login Button ───────────────────────────────────
                    AppButton(
                      label: 'Sign In',
                      onPressed: _submit,
                      variant: AppButtonVariant.elevated,
                      size: AppButtonSize.large,
                      fullWidth: true,
                      isLoading: authState.isLoading,
                    ),

                    const SizedBox(height: Spacings.xxl),

                    // ── Divider ────────────────────────────────────────
                    _buildDivider(cs, tt),

                    const SizedBox(height: Spacings.xxl),

                    // ── Social Login Buttons ────────────────────────────
                    _buildSocialButtons(cs, tt),

                    const SizedBox(height: Spacings.xxl),

                    // ── Register Link ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(RouteNames.register),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign Up',
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
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(Spacings.lgRadius),
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: Spacings.lg),
        Text(
          'Welcome Back',
          style: tt.headlineMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacings.sm),
        Text(
          'Sign in to continue to ExamForge AI',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ColorScheme cs, String error) {
    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(Spacings.smRadius),
        border: Border.all(color: cs.error.withOpacity(0.3)),
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

  Widget _buildDivider(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Expanded(child: Divider(color: cs.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
          child: Text(
            'OR',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: AppTypography.wSemiBold,
            ),
          ),
        ),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }

  Widget _buildSocialButtons(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Placeholder for Google Sign-In
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Google Sign-In coming soon')),
              );
            },
            icon: const Icon(Icons.g_mobiledata, size: Spacings.lgIcon),
            label: const Text('Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Spacings.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacings.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Placeholder for Apple Sign-In
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Apple Sign-In coming soon')),
              );
            },
            icon: const Icon(Icons.apple, size: Spacings.lgIcon),
            label: const Text('Apple'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: Spacings.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.mdRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
