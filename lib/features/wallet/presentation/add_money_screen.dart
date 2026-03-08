import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/card_provider.dart';
import '../../../models/card_model.dart';
import '../../../core/utils/card_utils.dart';
import '../../../core/services/email_service.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../providers/auth_provider.dart';

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  bool _isSuccess = false;
  String? _error;
  bool _isProcessing = false;

  // Custom Numpad state
  String _amountStr = '0';
  CardModel? _selectedCard;

  // OTP state
  bool _isVerifyingOtp = false;
  String _otpStr = '';
  String? _generatedOtp;

  void _onNumpadTap(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
      if (_isVerifyingOtp) {
        if (val == '<') {
          if (_otpStr.isNotEmpty) {
            _otpStr = _otpStr.substring(0, _otpStr.length - 1);
          }
        } else if (val != '.') {
          if (_otpStr.length < 6) {
            _otpStr += val;
            if (_otpStr.length == 6) {
              _verifyOtpAndAddFunds();
            }
          }
        }
      } else {
        if (val == '<') {
          if (_amountStr.length > 1) {
            _amountStr = _amountStr.substring(0, _amountStr.length - 1);
          } else {
            _amountStr = '0';
          }
        } else if (val == '.') {
          if (!_amountStr.contains('.')) {
            _amountStr += val;
          }
        } else {
          if (_amountStr == '0') {
            _amountStr = val;
          } else if (_amountStr.split('.').length > 1 &&
              _amountStr.split('.')[1].length >= 2) {
            return;
          } else {
            _amountStr += val;
          }
        }
        _amountCtrl.text = _amountStr;
      }
    });
  }

  Future<void> _handleProceed() async {
    if (_isVerifyingOtp) return;

    final amount = double.tryParse(_amountStr);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount');
      HapticFeedback.heavyImpact();
      return;
    }

    if (amount > 100000) {
      setState(() => _error = 'Maximum limit is ₹1,00,000 for single top-up');
      HapticFeedback.heavyImpact();
      return;
    }

    if (_selectedCard == null) {
      setState(() => _error = 'Please select a card');
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _error = null;
      _isProcessing = true;
    });
    HapticFeedback.mediumImpact();

    final user = ref.read(userDocProvider).value;
    if (user == null) {
      setState(() {
        _error = 'User session missing';
        _isProcessing = false;
      });
      return;
    }

    // Generate and send OTP
    final otp = (100000 + (DateTime.now().millisecond * 899) % 900000)
        .toString()
        .padLeft(6, '0');
    _generatedOtp = otp;

    try {
      final success = await EmailService.sendOtp(user.email, otp)
          .timeout(const Duration(seconds: 20));

      if (success) {
        if (mounted) {
          setState(() {
            _isVerifyingOtp = true;
            _otpStr = '';
            _isProcessing = false;
          });
          PremiumSnackbar.show(context, 'OTP sent to ${user.email}');
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to send OTP';
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Timeout sending OTP. Please try again.';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _verifyOtpAndAddFunds() async {
    if (_otpStr != _generatedOtp) {
      setState(() {
        _error = 'Invalid OTP. Please try again.';
        _otpStr = ''; // clear on fail
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _error = null;
      _isProcessing = true;
    });
    HapticFeedback.mediumImpact();

    final amount = double.tryParse(_amountStr)!;

    final success = await ref.read(walletControllerProvider.notifier).addFunds(
        amount,
        'Card: ${_selectedCard!.network.label} ending in ${_selectedCard!.lastFour}');

    if (success && mounted) {
      setState(() {
        _isSuccess = true;
        _isProcessing = false;
      });
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) context.go('/home');
      });
    } else {
      if (mounted) {
        setState(() {
          final err = ref.read(walletControllerProvider).error;
          _error = err != null
              ? err.toString()
              : 'Failed to add funds. Please try again.';
          _isProcessing = false;
          _otpStr = ''; // reset OTP
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isSuccess) return _buildSuccessState(isDark);

    final walletState = ref.watch(walletControllerProvider);
    final cardsAsync = ref.watch(cardProvider);
    final isLoading = walletState.isLoading || _isProcessing;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      if (_isVerifyingOtp)
                        _buildOtpDisplay(isDark)
                      else ...[
                        // Cards selector
                        cardsAsync.when(
                          data: (cards) {
                            if (cards.isEmpty) {
                              return _buildNoCardsState(isDark);
                            }
                            // Auto-select first card if none selected
                            if (_selectedCard == null && cards.isNotEmpty) {
                              _selectedCard = cards.first;
                            }
                            return _buildCardSelector(isDark, cards);
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Error loading cards: $e'),
                        ),
                        const SizedBox(height: 32),

                        // Amount Display
                        _buildAmountDisplay(isDark),
                      ],

                      // Error display
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBanner(isDark).animate().shake(),
                      ],
                    ],
                  ),
                ),
              ),

              // Custom Numpad & Proceed Button anchored to bottom
              _buildNumpad(isDark, isLoading)
                  .animate()
                  .slideY(begin: 0.5, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
              size: 28,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Add Money',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelector(bool isDark, List<CardModel> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Funding Card',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/cards'),
              child: const Text('Manage Cards', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isSelected = _selectedCard?.id == card.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCard = card);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: card.colors
                          .map((c) => Color(c)
                              .withValues(alpha: isSelected ? 1.0 : 0.4))
                          .toList(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Color(card.colors[0]).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(CardUtils.getNetworkIcon(card.network),
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '•••• ${card.lastFour}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.network.label,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10),
                      ),
                    ],
                  ),
                )
                    .animate(
                      target: isSelected ? 1 : 0,
                    )
                    .shimmer(
                      duration: 2.seconds,
                      color: Colors.white.withValues(alpha: 0.2),
                    )
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      curve: Curves.easeOutBack,
                    ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildNoCardsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.credit_card_off_rounded,
              color: AppColors.error, size: 40),
          const SizedBox(height: 16),
          const Text(
            'No Cards Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'You must add a card to your wallet before you can add money.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/cards'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to My Cards',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(bool isDark) {
    return Column(
      children: [
        Text(
          'Top Up Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _amountStr,
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                letterSpacing: -2,
                color: _amountStr == '0'
                    ? (isDark ? Colors.white24 : AppColors.textMuted)
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        // Quick amounts
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [500, 1000, 2000].map((val) {
            final active = _amountStr == val.toString();
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _amountStr = val.toString());
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.border),
                  ),
                ),
                child: Text(
                  '+ ₹$val',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColors.primary
                        : (isDark ? Colors.white54 : AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildOtpDisplay(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          'Security Verification',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to your email to authorize ₹$_amountStr.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final hasValue = index < _otpStr.length;
            final isActive = _otpStr.length == index;
            return Flexible(
              child: Container(
                width: 45,
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isActive
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05))
                      : (isActive
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : (isDark ? Colors.white12 : AppColors.border),
                    width: isActive ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: hasValue
                    ? Text(
                        _otpStr[index],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    ).animate().fadeIn();
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: isDark ? const Color(0xFFFFA4A4) : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(bool isDark, bool isLoading) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row in keys) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: row.map((key) {
                return _NumpadButton(
                  label: key,
                  isDark: isDark,
                  onTap: () => _onNumpadTap(key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 12),
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security_rounded,
                    size: 14, color: AppColors.success),
                SizedBox(width: 6),
                Text(
                  'Secured by PCI-DSS Encryption',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isVerifyingOtp
                              ? 'Enter OTP to add funds'
                              : 'Add Money Securely',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        if (!_isVerifyingOtp) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.3, 1.3),
                        duration: 1200.ms,
                        curve: Curves.easeInOut)
                    .fadeOut(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 80),
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Money Added!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
            const SizedBox(height: 16),
            Text(
              '₹$_amountStr has been added to\nyour PayPulse Wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _NumpadButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isAction = label == '<' || label == '.';
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.selectionClick(),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 60,
        alignment: Alignment.center,
        child: label == '<'
            ? Icon(
                Icons.backspace_outlined,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                size: 24,
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: isAction ? FontWeight.w500 : FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
      )
          .animate(autoPlay: false, onPlay: (c) => c.forward(from: 0))
          .scale(
              begin: const Offset(1, 1),
              end: const Offset(0.9, 0.9),
              duration: 100.ms,
              curve: Curves.easeOut)
          .then()
          .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 100.ms,
              curve: Curves.easeIn),
    );
  }
}
