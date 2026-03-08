import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../../../shared/widgets/app_input_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    ref.read(authControllerProvider.notifier).clearError();

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email: _emailCtrl.text);

    if (success && mounted) {
      setState(() => _emailSent = true);
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
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              // Body
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: (_emailSent
                            ? _buildSuccess(isDark)
                            : _buildForm(authState, isDark))
                        .animate()
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.04, end: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FORM STATE ──
  Widget _buildForm(AuthState authState, bool isDark) {
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
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text('Reset Password', style: AppTypography.h2),
            const SizedBox(height: 8),
            Text(
              'Enter your email and we\'ll send you\na link to reset your password.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 28),

            // Error banner
            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Email input
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
            const SizedBox(height: 28),

            // Send reset link button
            PrimaryButton(
              label: 'Send Reset Link',
              isLoading: authState.isLoading,
              onTap: _sendReset,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 16),

            // Back to login
            SecondaryButton(
              label: 'Back to Login',
              onTap: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }

  // ── SUCCESS STATE ──
  Widget _buildSuccess(bool isDark) {
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
      child: Column(
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.success,
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          Text('Check Your Email', style: AppTypography.h2),
          const SizedBox(height: 8),
          Text(
            'We sent a password reset link to',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            _emailCtrl.text,
            style: AppTypography.subtitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Back to Login',
            onTap: () => context.go('/login'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _emailSent = false);
              ref.read(authControllerProvider.notifier).clearError();
            },
            child: Text(
              'Didn\'t receive it? Try again',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
