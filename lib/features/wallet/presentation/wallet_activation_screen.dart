import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/email_service.dart';
import '../../../shared/widgets/premium_widgets.dart';

class WalletActivationScreen extends ConsumerStatefulWidget {
  const WalletActivationScreen({super.key});

  @override
  ConsumerState<WalletActivationScreen> createState() =>
      _WalletActivationScreenState();
}

class _WalletActivationScreenState
    extends ConsumerState<WalletActivationScreen> {
  int _currentStep = 0; // 0=KYC/Phone, 1=OTP, 2=PIN Setup, 3=Success
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  // KYC Fields
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // PIN Fields
  final _pinController = TextEditingController();

  // OTP Fields
  String _otp = '';
  String? _generatedOtp;
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(userDocProvider).value;
      if (user != null) {
        _nameController.text = user.name;
        if (user.phone != null) {
          _phoneController.text = user.phone!;
        }
      }
    });
  }

  void _nextStep() {
    if (_isProcessing) return;
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        _sendOtp();
      }
    } else if (_currentStep == 1) {
      _verifyOtp();
    } else if (_currentStep == 2) {
      if (_pinController.text.length == 4) {
        _activateWalletFinal();
      } else {
        PremiumSnackbar.show(context, 'Please enter a 4-digit PIN',
            isError: true);
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    final user = ref.read(userDocProvider).value;
    if (user == null) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      PremiumSnackbar.show(context, 'User session missing. Please login again.',
          isError: true);
      return;
    }

    // Generate 6 digit OTP
    final otp = (100000 + (DateTime.now().millisecond * 899) % 900000)
        .toString()
        .padLeft(6, '0');
    _generatedOtp = otp;

    bool success = false;
    try {
      success = await EmailService.sendOtp(user.email, otp)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      PremiumSnackbar.show(
        context,
        'OTP request timed out. Check internet and try again.',
        isError: true,
      );
      return;
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      PremiumSnackbar.show(
        context,
        'Failed to send OTP. Please try again.',
        isError: true,
      );
      return;
    }

    if (success) {
      setState(() {
        _currentStep = 1;
        _otp = '';
        _isProcessing = false;
      });
      PremiumSnackbar.show(context, 'OTP sent to ${user.email}');
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      PremiumSnackbar.show(context, 'Failed to send OTP', isError: true);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isProcessing) return;

    final enteredOtp = _otp.replaceAll(RegExp(r'\D'), '');
    final expectedOtp = (_generatedOtp ?? '').replaceAll(RegExp(r'\D'), '');

    if (expectedOtp.isEmpty) {
      PremiumSnackbar.show(context, 'OTP expired. Please resend code.',
          isError: true);
      return;
    }

    if (enteredOtp.length != 6) {
      PremiumSnackbar.show(context, 'Enter complete 6-digit OTP',
          isError: true);
      return;
    }

    if (enteredOtp != expectedOtp) {
      PremiumSnackbar.show(context, 'Invalid OTP', isError: true);
      return;
    }

    // OTP Verified, Move to PIN step
    setState(() {
      _currentStep = 2; // Move to PIN setup
    });
  }

  Future<void> _activateWalletFinal() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final success =
          await ref.read(authControllerProvider.notifier).activateWallet(
                phone: _phoneController.text,
                pin: _pinController.text,
              );

      if (success && mounted) {
        setState(() {
          _currentStep = 3; // Success screen
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go('/home');
        });
        return;
      }

      final authState = ref.read(authControllerProvider);
      final message =
          authState.error ?? 'Wallet activation failed. Please try again.';
      PremiumSnackbar.show(context, message, isError: true);
    } catch (e) {
      PremiumSnackbar.show(
        context,
        'Activation failed: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Wallet Activation',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? RadialGradient(
                  center: const Alignment(-0.5, -0.8),
                  radius: 1.5,
                  colors: [
                    AppColors.bgDark,
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.bgDark,
                  ],
                )
              : AppColors.bgGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              children: [
                _buildProgressIndicator(isDark)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: -0.5),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildStepContent(isDark),
                ),
                if (_currentStep < 2)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ]),
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _currentStep == 0
                                    ? 'Continue to Verification'
                                    : 'Verify & Activate',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 6,
          width: active ? 40 : 20,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : (isDark ? Colors.white12 : Colors.black12),
            borderRadius: BorderRadius.circular(3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCirc,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _currentStep == 0
          ? _buildKycStep(isDark)
          : _currentStep == 1
              ? _buildOtpStep(isDark)
              : _currentStep == 2
                  ? _buildPinStep(isDark)
                  : _buildSuccessStep(isDark),
    );
  }

  Widget _buildKycStep(bool isDark) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              key: const ValueKey('kyc_step'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      size: 32, color: AppColors.primary),
                )
                    .animate()
                    .fadeIn()
                    .scale(curve: Curves.easeOutBack, duration: 600.ms),
                const SizedBox(height: 24),
                const Text(
                  'Complete your KYC',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                const SizedBox(height: 12),
                Text(
                  'We need a few details to activate your digital wallet securely.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                const SizedBox(height: 32),
                _buildPremiumTextField(
                  controller: _nameController,
                  label: 'Full Name (as per ID)',
                  icon: Icons.badge_outlined,
                  isDark: isDark,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
                _buildPremiumTextField(
                  controller: _idController,
                  label: 'Aadhar / PAN Number',
                  icon: Icons.fingerprint_rounded,
                  isDark: isDark,
                  validator: (v) =>
                      v!.length < 10 ? 'Enter valid ID number' : null,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
                _buildPremiumTextField(
                  controller: _phoneController,
                  label: 'Mobile Number',
                  icon: Icons.phone_android_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.length < 10 ? 'Enter valid phone number' : null,
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.border,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 2.0),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          counterText: '', // Hide the length counter
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildOtpStep(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            key: const ValueKey('otp_step'),
            children: [
              const Text(
                'Verification Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to your email.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  final isActive = _otp.length == index;
                  final hasValue = index < _otp.length;
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12)
                            ]
                          : (isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]),
                    ),
                    alignment: Alignment.center,
                    child: hasValue
                        ? Text(
                            _otp[index],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                            .animate(key: ValueKey('otp_$index'))
                            .scale(curve: Curves.easeOutBack, duration: 200.ms)
                        : null,
                  );
                }),
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 28),
              _buildPremiumNumpad(isDark)
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _sendOtp,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: const Text('Resend Code'),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
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
            if (isAction && value == 'backspace') {
              if (_otp.isNotEmpty) _otp = _otp.substring(0, _otp.length - 1);
            } else if (!isAction && _otp.length < 6) {
              _otp += value;
              if (_otp.length == 6) {
                // Auto verify
                _verifyOtp();
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

  Widget _buildPinStep(bool isDark) {
    return Form(
      key: _formKey, // Reuse form validation approach visually
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              key: const ValueKey('pin_step'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 32, color: AppColors.primary),
                )
                    .animate()
                    .fadeIn()
                    .scale(curve: Curves.easeOutBack, duration: 600.ms),
                const SizedBox(height: 24),
                const Text(
                  'Set Security PIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
                const SizedBox(height: 12),
                Text(
                  'Create a 4-digit PIN to secure your wallet and confirm transactions.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                const SizedBox(height: 48),
                _buildPremiumTextField(
                  controller: _pinController,
                  label: 'Create 4-Digit PIN',
                  icon: Icons.password_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onChanged: (v) {
                    if (v.length == 4 && !_isProcessing) {
                      _activateWalletFinal();
                    }
                  },
                  validator: (v) =>
                      v!.length != 4 ? 'Enter exactly 4 digits' : null,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessStep(bool isDark) {
    return Column(
      key: const ValueKey('success_step'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 1.seconds,
                    curve: Curves.easeInOut)
                .then()
                .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(1, 1),
                    duration: 1.seconds,
                    curve: Curves.easeInOut),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 80,
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'Wallet Activated!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        Text(
          'Your PayPulse experience starts now.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
      ],
    );
  }
}
