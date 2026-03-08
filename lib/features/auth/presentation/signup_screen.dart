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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passCtrl.text != _confirmCtrl.text) {
      PremiumSnackbar.show(context, 'Passwords do not match', isError: true);
      return;
    }

    HapticFeedback.heavyImpact();
    ref.read(authControllerProvider.notifier).clearError();

    final success = await ref.read(authControllerProvider.notifier).sendOtp(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );

    if (success && mounted) {
      context.push(
        '/otp-verification?email=${Uri.encodeComponent(_emailCtrl.text.trim())}',
      );
      PremiumSnackbar.show(context, 'Verification code sent to your email!');
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                          onPressed: () => context.go('/login'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: AppTypography.h1,
                          ).animate().fadeIn().slideX(begin: -0.2),
                          const SizedBox(height: 6),
                          Text(
                            'Sign up to get started with PayPulse',
                            style: AppTypography.caption.copyWith(fontSize: 14),
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                          const SizedBox(height: 36),
                          _buildForm(authState)
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .scale(begin: const Offset(0.95, 0.95)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
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
          top: -100,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.07),
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
                begin: const Offset(20, -20),
                end: const Offset(-20, 20),
              ),
        ),
      ],
    );
  }

  Widget _buildForm(AuthState authState) {
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
                ? AppColors.bgDark.withValues(alpha: 0.82)
                : AppColors.surfaceLight.withValues(alpha: 0.56),
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
          children: [
            AppInputField(
              controller: _nameCtrl,
              hint: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 2) return 'Enter your full name';
                return null;
              },
            ),
            const SizedBox(height: 16),
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
              obscure: _obscure1,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscure1 = !_obscure1),
                child: Icon(
                  _obscure1
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
            const SizedBox(height: 16),
            AppInputField(
              controller: _confirmCtrl,
              hint: 'Confirm Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: _obscure2,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscure2 = !_obscure2),
                child: Icon(
                  _obscure2
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                return null;
              },
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Create Account',
              isLoading: authState.isLoading,
              onTap: _register,
            ),
          ],
        ),
      ),
    );
  }
}
