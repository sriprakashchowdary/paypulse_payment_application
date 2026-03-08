import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_input_field.dart';
import '../../../shared/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.heavyImpact();

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(email: _emailCtrl.text, password: _passCtrl.text);

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        PremiumSnackbar.show(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.bgGradientDark : AppColors.bgGradient,
        ),
        child: Stack(
          children: [
            _buildOrbs(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      _buildLogo()
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: -0.2),
                      const SizedBox(height: 48),
                      _buildCard(authState)
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                      const SizedBox(height: 28),
                      _buildFooter().animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 4.seconds,
              )
              .move(
                begin: const Offset(-20, -20),
                end: const Offset(20, 20),
              ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
                duration: 5.seconds,
              )
              .move(
                begin: const Offset(20, 20),
                end: const Offset(-20, -20),
              ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Lottie.asset(
            'assets/animations/login_character.json',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text('PayPulse', style: AppTypography.h1),
        const SizedBox(height: 6),
        Text(
          'Your AI-Powered Digital Wallet',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AuthState authState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.cardDark.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.98),
            isDark
                ? AppColors.bgDark.withValues(alpha: 0.8)
                : AppColors.surfaceLight.withValues(alpha: 0.58),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.xxl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: isDark ? [] : Shadows.soft,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back', style: AppTypography.h2),
            const SizedBox(height: 4),
            Text('Sign in to continue', style: AppTypography.caption),
            const SizedBox(height: 28),
            AppInputField(
              controller: _emailCtrl,
              hint: 'Email address',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppInputField(
              controller: _passCtrl,
              hint: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscure,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.go('/forgot-password'),
                child: Text(
                  'Forgot Password?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Sign In',
              isLoading: authState.isLoading,
              onTap: _login,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: AppTypography.bodySmall),
        TextButton(
          onPressed: () => context.go('/signup'),
          child: Text(
            'Sign Up',
            style: AppTypography.button.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
