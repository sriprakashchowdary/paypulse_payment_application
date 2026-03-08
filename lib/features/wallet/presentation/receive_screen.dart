import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';

/// Premium Receive Money Screen — shows user's QR code with animations.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Email copied to clipboard!',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(userDocProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: Stack(
          children: [
            // Animated background orbs
            _buildBackgroundOrbs(isDark),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(isDark),
                  Expanded(
                    child: userAsync.when(
                      data: (user) {
                        final name = ref.watch(
                            userDocProvider.select((u) => u.value?.name ?? ''));
                        final email = ref.watch(userDocProvider
                            .select((u) => u.value?.email ?? ''));
                        final uid = ref.watch(
                            userDocProvider.select((u) => u.value?.uid ?? ''));

                        if (name.isEmpty) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary));
                        }
                        return _buildContent(name, email, uid, isDark);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      error: (e, _) => Center(child: Text('Error: $e')),
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

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Receive Money',
            style: AppTypography.title.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildContent(String name, String email, String uid, bool isDark) {
    // QR data encodes the user email as the payment target
    final qrData =
        'paypulse://send?email=${Uri.encodeComponent(email)}&name=${Uri.encodeComponent(name)}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Instruction text
          Text(
            'Show this QR code to receive',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 4),
          Text(
            'money directly to your wallet',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 36),

          // QR card
          _buildQrCard(name, email, qrData, isDark)
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.85, 0.85), curve: Curves.elasticOut),

          const SizedBox(height: 32),

          // Bottom info strip
          _buildInfoStrip(isDark)
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.3),

          const SizedBox(height: 20),

          // Copy button
          GestureDetector(
            onTap: () => _copyEmail(email),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Copy Email Address',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQrCard(String name, String email, String qrData, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.3 + (_pulseController.value * 0.2),
                ),
                blurRadius: 40 + (_pulseController.value * 20),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.secondary.withValues(
                  alpha: 0.2 + (_pulseController.value * 0.15),
                ),
                blurRadius: 60,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.95) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.border,
                  width: 1.5),
            ),
            child: Column(
              children: [
                // User avatar + name header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.title.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'PayPulse Wallet',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // PayPulse badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PayPulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                // Divider
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.border,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // QR Code with corner decorators
                Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    // Center logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Email label below QR
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        email,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoStrip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.border,
        ),
        boxShadow: isDark ? [] : Shadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment QR',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Only share with people you trust',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(
                      alpha: isDark
                          ? 0.15 + _pulseController.value * 0.1
                          : 0.08 + _pulseController.value * 0.06,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -60,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(
                      alpha: isDark
                          ? 0.15 + (1 - _pulseController.value) * 0.1
                          : 0.08 + (1 - _pulseController.value) * 0.06,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
