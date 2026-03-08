import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/premium_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // HIDDEN BY DEFAULT
  bool _hideAmounts = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final user = ref.read(userDocProvider).value;
      if (user != null && user.isWalletActive && user.pulseCredit <= 0) {
        await ref.read(walletControllerProvider.notifier).seedPulseCredit();
      }
    });
  }

  void _toggleHideAmounts() {
    HapticFeedback.selectionClick();

    // If it's already hidden and they want to reveal it:
    if (_hideAmounts) {
      final user = ref.read(userDocProvider).value;
      if (user == null) return;

      // If user hasn't set up a PIN yet, just reveal it immediately
      if (user.walletPin == null || user.walletPin!.isEmpty) {
        setState(() => _hideAmounts = false);
        return;
      }

      // Show secure unlock bottom sheet
      _showSecureUnlockSheet(user.walletPin!);
    } else {
      // If it's visible, let them hide it instantly without a PIN
      setState(() => _hideAmounts = true);
    }
  }

  void _showSecureUnlockSheet(String correctPin) {
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
                    setState(() => _hideAmounts = false); // Reveal amounts
                    PremiumSnackbar.show(context, l10n.walletUnlocked);
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.revealBalanceDesc,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppColors.primary
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Numpad
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 24),
                    child: Column(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (int j = 1; j <= 3; j++)
                                  _buildPinButton(
                                      '${i * 3 + j}', isDark, onNumber),
                              ],
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 72),
                            _buildPinButton('0', isDark, onNumber),
                            _buildPinButton(
                                '🔙', isDark, (val) => onBackspace()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCashbackHistorySheet() {
    final txnsAsync = ref.read(transactionsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.card_giftcard_rounded,
                  size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'Cashback History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: txnsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (items) {
                    final rewards = items
                        .where((tx) => tx.title == 'Cashback Reward')
                        .toList();

                    if (rewards.isEmpty) {
                      return const Center(child: Text('No cashback yet!'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final tx = rewards[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TransactionCard(
                            title: tx.title ?? 'Cashback',
                            amount: tx.amount,
                            date: tx.timestamp,
                            isCredit: true,
                            type: tx.type,
                            category: tx.category,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVaultManagementSheet() {
    final user = ref.read(userDocProvider).value;
    final vault = user?.savingsVault ?? 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Savings Vault',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Auto-saved from your roundup payments',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Vault Balance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${vault.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PrimaryButton(
                  label: 'Transfer to Wallet',
                  onTap: vault > 0 ? () => _showVaultActionDialog(vault) : null,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Transfers from vault are instant and go directly to your main wallet balance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVaultActionDialog(double limit) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Transfer to Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available in Vault: ₹${limit.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter amount',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Transfer',
            onTap: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > limit) {
                PremiumSnackbar.show(dialogContext, 'Invalid amount',
                    isError: true);
                return;
              }

              Navigator.pop(dialogContext);
              Navigator.pop(context);

              final success = await ref
                  .read(walletControllerProvider.notifier)
                  .withdrawFromVault(amount);

              if (success) {
                PremiumSnackbar.show(context, 'Transfer successful!');
              } else {
                final error = ref.read(walletControllerProvider).error;
                PremiumSnackbar.show(
                  context,
                  error?.toString().replaceAll('Exception: ', '') ??
                      'Transfer failed. Please try again.',
                  isError: true,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCreditManagementSheet() {
    final user = ref.read(userDocProvider).value;
    if (user == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const totalLimit = 2000.0;
    final available = user.pulseCredit;
    final used = (totalLimit - available).clamp(0.0, totalLimit);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.bolt_rounded, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'Pulse Credit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Instant money when you need it',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _buildCreditStat(
                    'Available',
                    available,
                    Colors.green,
                    isDark,
                  ),
                  const SizedBox(width: 16),
                  _buildCreditStat(
                    'Used',
                    used,
                    Colors.orange,
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Withdraw',
                      onTap: available > 0
                          ? () => _showCreditActionDialog('Withdraw', available)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Repay',
                      onTap: used > 0
                          ? () => _showCreditActionDialog('Repay', used)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreditStat(
      String label, double amount, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toInt()}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreditActionDialog(String action, double limit) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      useRootNavigator: false, // Keep it on the same navigator as the sheet
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('$action Credit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Max available: ₹${limit.toInt()}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Confirm',
            onTap: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > limit) {
                PremiumSnackbar.show(dialogContext, 'Invalid amount',
                    isError: true);
                return;
              }

              // Close both dialog and sheet safely
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close bottom sheet (context of sheet)

              bool success = false;
              if (action == 'Withdraw') {
                success = await ref
                    .read(walletControllerProvider.notifier)
                    .withdrawCredit(amount);
              } else {
                success = await ref
                    .read(walletControllerProvider.notifier)
                    .repayCredit(amount);
              }

              if (success) {
                PremiumSnackbar.show(context, '$action successful!');
              } else {
                final error = ref.read(walletControllerProvider).error;
                PremiumSnackbar.show(
                  context,
                  error?.toString().replaceAll('Exception: ', '') ??
                      'Failed to $action. Please try again.',
                  isError: true,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinButton(String value, bool isDark, Function(String) onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(value);
      },
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: isDark || value == '🔙' ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    await ref.read(themeProvider.notifier).toggleTheme();
  }

  void _openRoute(String route) {
    HapticFeedback.lightImpact();
    context.push(route);
  }

  List<Widget> _buildRecentTransactions(
    ThemeData theme,
    AsyncValue<List<dynamic>> txnsAsync,
    String uid,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            children: [
              Text(l10n.recentActivity, style: theme.textTheme.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/history'),
                child: Text(l10n.viewAll),
              ),
            ],
          ),
        ),
      ),
      txnsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
        error: (e, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(Radii.xl),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(l10n.noTransactionsFound),
                ),
              ),
            );
          }

          final recent = items.take(5).toList();
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList.builder(
              itemCount: recent.length,
              itemBuilder: (context, index) {
                final tx = recent[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TransactionCard(
                    title: tx.title ?? 'Transaction',
                    amount: tx.amount,
                    date: tx.timestamp,
                    isCredit: tx.isCredit(uid),
                    type: tx.type,
                    category: tx.category,
                  ),
                );
              },
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(userDocProvider);
    final txnsAsync = ref.watch(transactionsStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authControllerProvider.notifier).currentUid ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (user) {
            final name = (user?.name.isNotEmpty ?? false)
                ? user!.name.split(' ').first
                : 'Guest';
            final walletActive = user?.isWalletActive ?? false;
            final pulseScore = ref.watch(pulseScoreProvider);

            return Stack(
              children: [
                const Positioned.fill(child: _LuxuryBackground()),
                SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: _HomeHeader(
                            name: name,
                            isDark: isDark,
                            hideAmounts: _hideAmounts,
                            onToggleHide: _toggleHideAmounts,
                            onToggleTheme: _toggleTheme,
                          ).animate().fadeIn(duration: 320.ms).slideY(
                                begin: -0.04,
                                end: 0,
                                duration: 320.ms,
                              ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: walletActive
                              ? WalletCard(
                                  balance: user?.walletBalance ?? 0,
                                  pulseScore: pulseScore,
                                  isStealth: _hideAmounts,
                                  statusLabel: l10n.active,
                                  onTap: () => _openRoute('/cards'),
                                )
                              : _ActivateWalletCard(
                                  isDark: isDark,
                                  onTap: () => context.push('/activate-wallet'),
                                )
                                  .animate()
                                  .fadeIn(delay: 80.ms, duration: 360.ms)
                                  .slideY(begin: 0.05, end: 0),
                        ),
                      ),
                      if (walletActive)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              children: [
                                _WalletActionButton(
                                  label: 'Credit',
                                  value:
                                      '₹${(user?.pulseCredit ?? 2000).toInt()}',
                                  icon: Icons.bolt_rounded,
                                  color: Colors.amber,
                                  isDark: isDark,
                                  onTap: _showCreditManagementSheet,
                                ),
                                const SizedBox(width: 8),
                                _WalletActionButton(
                                  label: 'Vault',
                                  value: '₹${user?.savingsVault.toInt() ?? 0}',
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: Colors.blue,
                                  isDark: isDark,
                                  onTap: _showVaultManagementSheet,
                                ),
                                const SizedBox(width: 8),
                                _WalletActionButton(
                                  label: 'Cashback',
                                  value: '₹${user?.totalCashback.toInt() ?? 0}',
                                  icon: Icons.card_giftcard_rounded,
                                  color: Colors.green,
                                  isDark: isDark,
                                  onTap: _showCashbackHistorySheet,
                                ),
                              ],
                            ).animate().fadeIn(delay: 120.ms).slideY(
                                  begin: 0.04,
                                  end: 0,
                                ),
                          ),
                        ),
                      // Alerts moved to Notifications in Settings
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: _GlassPanel(
                            child: _QuickActions(
                              enabled: walletActive,
                              onAddMoney: () => _openRoute('/add-money'),
                              onSend: () => _openRoute('/send-money'),
                              onReceive: () => _openRoute('/receive'),
                              onSplit: () => _openRoute('/split-receipt'),
                              onCards: () => _openRoute('/cards'),
                              onGold: () => _openRoute('/gold'),
                              onScan: () => _openRoute('/qr-scanner'),
                              onHistory: () => context.go('/history'),
                            ),
                          ).animate().fadeIn(delay: 160.ms).slideY(
                                begin: 0.04,
                                end: 0,
                              ),
                        ),
                      ),
                      ..._buildRecentTransactions(theme, txnsAsync, uid),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String name;
  final bool isDark;
  final bool hideAmounts;
  final VoidCallback onToggleHide;
  final VoidCallback onToggleTheme;

  const _HomeHeader({
    required this.name,
    required this.isDark,
    required this.hideAmounts,
    required this.onToggleHide,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.welcomeBack,
                style: textTheme.bodySmall?.copyWith(
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(name, style: textTheme.headlineMedium),
            ],
          ),
        ),
        _IconChip(
          icon: hideAmounts
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          onTap: onToggleHide,
        ),
        const SizedBox(width: 8),
        _IconChip(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: onToggleTheme,
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1.1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          width: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).cardColor.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _WalletActionButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                  isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.border.withValues(alpha: 0.5),
              ),
              boxShadow: isDark ? [] : Shadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivateWalletCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ActivateWalletCard({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.cardDark : Colors.white,
            isDark
                ? AppColors.bgDark.withValues(alpha: 0.7)
                : AppColors.surfaceLight.withValues(alpha: 0.48),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: isDark ? [] : Shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            'Activate your wallet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Finish quick verification to unlock add money, transfers, and cards.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Activate now', onTap: onTap),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool enabled;
  final VoidCallback onAddMoney;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onSplit;
  final VoidCallback onCards;
  final VoidCallback onGold;
  final VoidCallback onScan;
  final VoidCallback onHistory;

  const _QuickActions({
    required this.enabled,
    required this.onAddMoney,
    required this.onSend,
    required this.onReceive,
    required this.onSplit,
    required this.onCards,
    required this.onGold,
    required this.onScan,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = <({String label, IconData icon, VoidCallback onTap})>[
      (label: l10n.add, icon: Icons.add_card_rounded, onTap: onAddMoney),
      (label: l10n.send, icon: Icons.send_rounded, onTap: onSend),
      (label: l10n.receive, icon: Icons.qr_code_rounded, onTap: onReceive),
      (label: l10n.split, icon: Icons.group_add_rounded, onTap: onSplit),
      (label: l10n.cards, icon: Icons.credit_card_rounded, onTap: onCards),
      (label: l10n.gold, icon: Icons.auto_awesome_rounded, onTap: onGold),
      (label: l10n.scan, icon: Icons.qr_code_scanner_rounded, onTap: onScan),
      (label: l10n.history, icon: Icons.history_rounded, onTap: onHistory),
    ];

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !enabled,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Material(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.lg),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.lg),
                onTap: action.onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).cardColor,
                        Theme.of(context).cardColor.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, color: AppColors.primary),
                      const SizedBox(height: 6),
                      Text(
                        action.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LuxuryBackground extends StatelessWidget {
  const _LuxuryBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _glow(
              AppColors.primary.withValues(alpha: isDark ? 0.26 : 0.18),
              280,
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: _glow(
              AppColors.secondary.withValues(alpha: isDark ? 0.22 : 0.14),
              260,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? AppColors.cardDark : Colors.white)
                .withValues(alpha: 0.94),
            (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                .withValues(alpha: 0.66),
          ],
        ),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: isDark ? [] : Shadows.card,
      ),
      child: child,
    );
  }
}
