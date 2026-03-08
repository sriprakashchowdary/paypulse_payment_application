import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/app_preferences_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/wallet_provider.dart';

import '../../../shared/widgets/premium_widgets.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? recipientName;
  const SendMoneyScreen({super.key, this.initialEmail, this.recipientName});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  bool _isSuccess = false;
  String? _error;
  bool _isFromQr = false;

  // Custom Numpad state
  String _amountStr = '0';

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
      _isFromQr = true;
    }
  }

  void _onNumpadTap(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      _error = null;
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
          // Max 2 decimal places
          return;
        } else {
          _amountStr += val;
        }
      }
      _amountCtrl.text = _amountStr;
    });
  }

  Future<void> _handleSend() async {
    final l10n = AppLocalizations.of(context)!;
    final appPrefs = ref.read(appPreferencesProvider);
    if (appPrefs.emergencyLock) {
      setState(() {
        _error =
            'Emergency lock is enabled. Disable it in Settings to send money.';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    final email = _emailCtrl.text.trim();
    final amount = double.tryParse(_amountStr);

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = l10n.invalidReceiverEmail);
      HapticFeedback.heavyImpact();
      return;
    }

    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.invalidAmount);
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _error = null);
    HapticFeedback.mediumImpact();

    final user = ref.read(userDocProvider).value;
    if (user?.walletPin != null && user!.walletPin!.isNotEmpty) {
      _showPinVerificationSheet(user.walletPin!);
    } else {
      _executeTransfer(amount, email);
    }
  }

  Future<void> _executeTransfer(double amount, String email) async {
    final success = await ref
        .read(walletControllerProvider.notifier)
        .transferFunds(amount, email);

    if (success && mounted) {
      setState(() => _isSuccess = true);
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) context.go('/home');
      });
    } else if (mounted) {
      final state = ref.read(walletControllerProvider);
      if (state.hasError) {
        setState(
          () => _error = state.error.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _showPinVerificationSheet(String correctPin) {
    String enteredPin = '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void onNumber(String num) {
              if (enteredPin.length < 4) {
                setSheetState(() => enteredPin += num);
                if (enteredPin.length == 4) {
                  if (enteredPin == correctPin) {
                    Navigator.pop(context); // Close sheet
                    final amount = double.tryParse(_amountStr);
                    final email = _emailCtrl.text.trim();
                    if (amount != null && email.isNotEmpty) {
                      _executeTransfer(amount, email);
                    }
                  } else {
                    setSheetState(() => enteredPin = '');
                    PremiumSnackbar.show(context, l10n.incorrectPin,
                        isError: true);
                  }
                }
              }
            }

            void onBackspace() {
              if (enteredPin.isNotEmpty) {
                setSheetState(() => enteredPin =
                    enteredPin.substring(0, enteredPin.length - 1));
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.lock_rounded,
                      size: 40, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    l10n.enterWalletPin,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.authorizeTransfer,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool filled = index < enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? AppColors.primary
                              : (isDark ? Colors.white10 : Colors.black12),
                          border: Border.all(
                            color: filled
                                ? AppColors.primary
                                : (isDark ? Colors.white24 : Colors.black26),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  // Numpad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        for (var row in [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          ['', '0', '<']
                        ]) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: row.map((key) {
                              if (key.isEmpty) return const SizedBox(width: 60);
                              return _NumpadButton(
                                label: key,
                                isDark: isDark,
                                onTap: () =>
                                    key == '<' ? onBackspace() : onNumber(key),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isSuccess) return _buildSuccessState(isDark);

    final walletState = ref.watch(walletControllerProvider);
    final appPrefs = ref.watch(appPreferencesProvider);
    final isLoading = walletState.isLoading;

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
                      // Recipient Field
                      _buildRecipientField(isDark),
                      const SizedBox(height: 32),

                      // Amount Display
                      _buildAmountDisplay(isDark),

                      if (appPrefs.emergencyLock) ...[
                        const SizedBox(height: 16),
                        _buildLockBanner(isDark),
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

              // Custom Numpad & Send Button anchored to bottom
              if (!isKeyboardVisible)
                _buildNumpad(isDark, isLoading, appPrefs.emergencyLock)
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
            'Transfer',
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

  Widget _buildRecipientField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isFromQr)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Scanned from QR',
                  style: TextStyle(
                    color: isDark ? AppColors.success : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
        Text(
          'To',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: TextField(
            controller: _emailCtrl,
            keyboardType:
                TextInputType.emailAddress, // Allows both text and numbers
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Email or Mobile Number',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : AppColors.textMuted,
              ),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded,
                    color: AppColors.secondary, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay(bool isDark) {
    return Column(
      children: [
        Text(
          'Amount',
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
      ],
    ).animate().fadeIn(delay: 100.ms);
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

  Widget _buildNumpad(bool isDark, bool isLoading, bool isLocked) {
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
          const SizedBox(height: 16),
          // Send Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (isLoading || isLocked) ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Send Securely',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.lock_outline_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withValues(alpha: 0.18)
            : AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.36)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_moon_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Emergency Lock is ON. Outgoing transfers are paused.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 80),
              ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.transferSuccessful,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
            const SizedBox(height: 16),
            Text(
              '₹$_amountStr ${l10n.sentTo}\n${_emailCtrl.text}',
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
      ),
    );
  }
}
