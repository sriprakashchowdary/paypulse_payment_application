import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/premium_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (i) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (i) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      PremiumSnackbar.show(
        context,
        'Please enter the full 6-digit code',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final success =
        await ref.read(authControllerProvider.notifier).verifyOtp(otp);

    if (success && mounted) {
      context.go('/home');
      PremiumSnackbar.show(context, 'Account verified successfully!');
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
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader().animate().fadeIn().slideX(begin: -0.2),
                          const SizedBox(height: 40),
                          _buildOtpContainer(authState)
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .scale(begin: const Offset(0.95, 0.95)),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to:',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpContainer(AuthState authState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildOtpCell(index, isDark)),
        ),
        const SizedBox(height: 64),
        _buildPremiumNumpad(isDark)
            .animate()
            .fadeIn(delay: 400.ms)
            .slideY(begin: 0.2),
        const SizedBox(height: 32),
        if (authState.isLoading)
          const CircularProgressIndicator()
        else
          TextButton(
            onPressed: () async {
              final success =
                  await ref.read(authControllerProvider.notifier).resendOtp();
              if (success && mounted) {
                PremiumSnackbar.show(
                  context,
                  'OTP resent to ${widget.email}',
                );
              } else if (mounted) {
                final error = ref.read(authControllerProvider).error;
                if (error != null) {
                  PremiumSnackbar.show(context, error, isError: true);
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            child: const Text('Resend Code'),
          ),
      ],
    );
  }

  Widget _buildOtpCell(int index, bool isDark) {
    final otpText = _controllers.map((c) => c.text).join();
    final isActive = otpText.length == index;
    final hasValue = index < otpText.length;

    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: isDark
            ? (isActive
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05))
            : (isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : (isDark ? Colors.white12 : AppColors.border),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12)
              ]
            : (isDark
                ? []
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]),
      ),
      alignment: Alignment.center,
      child: hasValue
          ? Text(
              otpText[index],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            )
              .animate(key: ValueKey('otp_${index}_$hasValue'))
              .scale(curve: Curves.easeOutBack, duration: 200.ms)
          : null,
    );
  }

  Widget _buildPremiumNumpad(bool isDark) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var j = 1; j <= 3; j++)
                  _buildNumpadButton((i * 3 + j).toString(), isDark),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72), // Empty space for alignment
            _buildNumpadButton('0', isDark),
            _buildNumpadButton('backspace', isDark, isAction: true),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadButton(String value, bool isDark,
      {bool isAction = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            final otpText = _controllers.map((c) => c.text).join();

            if (isAction && value == 'backspace') {
              if (otpText.isNotEmpty) {
                _controllers[otpText.length - 1].text = '';
              }
            } else if (!isAction && otpText.length < 6) {
              _controllers[otpText.length].text = value;
              if (otpText.length + 1 == 6) {
                // Auto verify
                _verify();
              }
            }
          });
        },
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        highlightColor: AppColors.primary.withValues(alpha: 0.1),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
          ),
          child: isAction
              ? Icon(Icons.backspace_rounded,
                  color: isDark ? Colors.white70 : Colors.black87, size: 28)
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOrbs() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
