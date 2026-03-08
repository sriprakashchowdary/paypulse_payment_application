import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../models/card_model.dart';
import '../../../providers/card_provider.dart';
import '../../../core/utils/card_utils.dart';
import 'package:card_scanner/card_scanner.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  // State for Add Card modal
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _nameController = TextEditingController();
  CardNetwork _detectedNetwork = CardNetwork.unknown;

  @override
  void dispose() {
    _pageController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleFreeze(CardModel card) {
    HapticFeedback.mediumImpact();
    ref
        .read(cardControllerProvider.notifier)
        .toggleFreeze(card.id, card.isFrozen);
    PremiumSnackbar.show(
      context,
      card.isFrozen
          ? AppLocalizations.of(context)!.unfreezeCard
          : AppLocalizations.of(context)!.freezeCard,
      isError: false,
    );
  }

  void _toggleDetails(CardModel card) {
    HapticFeedback.lightImpact();
    ref
        .read(cardControllerProvider.notifier)
        .toggleDetailsVisibility(card.id, card.isDetailsVisible);
  }

  void _removeCard(String cardId, AppLocalizations l10n) {
    HapticFeedback.heavyImpact();
    ref.read(cardControllerProvider.notifier).deleteCard(cardId);
    PremiumSnackbar.show(context, l10n.cardRemovedSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    try {
      final l10n = AppLocalizations.of(context)!;

      // Auth state will seamlessly propagate to cardProvider,
      // no need to prematurely block the screen rendering here.
      final cardsAsync = ref.watch(cardProvider);

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          body: cardsAsync.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (cards) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(cardProvider);
                await ref.read(cardProvider.future);
              },
              child: _buildBody(context, cards, isDark, l10n),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load cards:\n${e.toString().replaceAll('Exception: ', '')}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Retry',
                      onTap: () => ref.invalidate(cardProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text('Something went wrong: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(cardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, List<CardModel> cards, bool isDark,
      AppLocalizations l10n) {
    // Current index safety
    if (_currentIndex >= cards.length && cards.isNotEmpty) {
      _currentIndex = cards.length - 1;
    }

    return Stack(
      children: [
        // Background ambient lighting
        if (isDark && cards.isNotEmpty)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(
                      cards[_currentIndex].colors[0],
                    ).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        Positioned.fill(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark, l10n),
                const SizedBox(height: 24),
                if (cards.isEmpty)
                  _buildEmptyState(isDark, l10n)
                else ...[
                  // Cards Carousel
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = index);
                      },
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedCard(index, cards[index], isDark);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Card Controls
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
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
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Spending Limit Progress
                            _buildLimitProgress(cards[_currentIndex], isDark),
                            const SizedBox(height: 32),

                            Text(
                              l10n.cardDetails,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Control Actions
                            _buildControlTile(
                              icon: Icons.ac_unit_rounded,
                              title: cards[_currentIndex].isFrozen
                                  ? l10n.unfreezeCard
                                  : l10n.freezeCard,
                              subtitle: cards[_currentIndex].isFrozen
                                  ? l10n.unfreezeCardDesc
                                  : l10n.freezeCardDesc,
                              isDark: isDark,
                              onTap: () => _toggleFreeze(cards[_currentIndex]),
                            ),
                            _buildControlTile(
                              icon: cards[_currentIndex].isDetailsVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              title: cards[_currentIndex].isDetailsVisible
                                  ? l10n.hideDetails
                                  : l10n.showDetails,
                              subtitle: l10n.detailsDesc,
                              isDark: isDark,
                              onTap: () => _toggleDetails(cards[_currentIndex]),
                            ),
                            _buildControlTile(
                              icon: Icons.delete_outline_rounded,
                              title: l10n.removeCard,
                              subtitle: l10n.removeCardDesc,
                              isDark: isDark,
                              isDestructive: true,
                              onTap: () =>
                                  _removeCard(cards[_currentIndex].id, l10n),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 0.2, curve: Curves.easeOutCubic),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: PrimaryButton(
                      label: l10n.addNewCard,
                      onTap: () => _showAddCardModal(l10n),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.cards,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: InkWell(
              onTap: () => _showAddCardModal(l10n),
              child: Icon(
                Icons.add_rounded,
                color: isDark ? Colors.white : AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(int index, CardModel card, bool isDark) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
        }

        final rotateY =
            index == _currentIndex ? 0.0 : (index > _currentIndex ? 0.2 : -0.2);

        return Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 220,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotateY * (1 - value)),
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: card.isFrozen
                          ? [Colors.grey.shade800, Colors.grey.shade900]
                          : card.colors.map((c) => Color(c)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Color(
                          card.colors[0],
                        ).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Icon(
                          Icons.account_balance_wallet,
                          size: 160,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  card.network.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    fontSize: 16,
                                  ),
                                ),
                                Icon(
                                  CardUtils.getNetworkIcon(
                                    card.network,
                                  ),
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: 300.ms,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                  child: Text(
                                    card.isDetailsVisible
                                        ? CardUtils.formatCardNumber(
                                            card.cardNumber,
                                          )
                                        : '**** **** **** ${card.lastFour}',
                                    key: ValueKey(
                                      card.isDetailsVisible,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      color: card.isFrozen
                                          ? Colors.white54
                                          : Colors.white,
                                      fontSize: 18,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      card.cardholderName,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: 300.ms,
                                      child: Text(
                                        card.isDetailsVisible
                                            ? card.expiryDate
                                            : '**/**',
                                        key: ValueKey(
                                          'exp_${card.isDetailsVisible}',
                                        ),
                                        style: TextStyle(
                                          color: card.isFrozen
                                              ? Colors.white54
                                              : Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (card.isFrozen)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.ac_unit_rounded,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (index * 100).ms)
              .scale(begin: const Offset(0.9, 0.9)),
        );
      },
    );
  }

  Widget _buildLimitProgress(CardModel card, bool isDark) {
    final spent = card.monthlySpent;
    final limit = card.monthlyLimit;
    final ratio = (spent / limit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.bgLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Limit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white12 : AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                ratio > 0.8 ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color mainColor = isDestructive ? AppColors.error : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A374A) : AppColors.border,
          ),
          boxShadow: isDark ? [] : Shadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: mainColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white24 : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 80,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noCardsYet,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                l10n.noCardsDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: PrimaryButton(
                label: l10n.addNewCard,
                onTap: () => _showAddCardModal(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardModal(AppLocalizations l10n) {
    _cardNumberController.clear();
    _expiryController.clear();
    _nameController.clear();
    _detectedNetwork = CardNetwork.unknown;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addNewCard,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                maxLength: 19,
                decoration: InputDecoration(
                  labelText: l10n.cardNumber,
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.document_scanner_rounded),
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                        onPressed: () async {
                          try {
                            CardDetails? cardDetails =
                                await CardScanner.scanCard(
                              scanOptions: CardScanOptions(
                                scanCardHolderName: true,
                                scanExpiryDate: true,
                              ),
                            );
                            if (cardDetails != null) {
                              setModalState(() {
                                // Always update card number
                                _cardNumberController.text =
                                    CardUtils.formatCardNumber(
                                  cardDetails.cardNumber,
                                );
                                _detectedNetwork = CardUtils.getCardNetwork(
                                  _cardNumberController.text,
                                );

                                // Optionally update expiry and name if detected
                                if (cardDetails.expiryDate.isNotEmpty) {
                                  _expiryController.text =
                                      cardDetails.expiryDate;
                                }
                                if (cardDetails.cardHolderName.isNotEmpty) {
                                  _nameController.text =
                                      cardDetails.cardHolderName;
                                }
                              });
                            }
                          } catch (e) {
                            debugPrint('Card Scan Error: $e');
                            if (mounted) {
                              PremiumSnackbar.show(
                                context,
                                'Could not scan card. Please enter manually.',
                                isError: true,
                              );
                            }
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          CardUtils.getNetworkIcon(_detectedNetwork),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (value) {
                  final formatted = CardUtils.formatCardNumber(value);
                  if (formatted != value) {
                    _cardNumberController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                  setModalState(() {
                    _detectedNetwork = CardUtils.getCardNetwork(formatted);
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.cardDetails}: ${_detectedNetwork.label}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.expiryDateHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.cvv,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.cardHolderName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: PrimaryButton(
                  label: l10n.saveCard,
                  isLoading: ref.watch(cardControllerProvider).isLoading,
                  onTap: () async {
                    final normalizedCardNumber = CardUtils.formatCardNumber(
                      _cardNumberController.text,
                    );
                    if (normalizedCardNumber.replaceAll(' ', '').length < 13) {
                      PremiumSnackbar.show(
                        context,
                        'Please enter a valid card number',
                        isError: true,
                      );
                      return;
                    }
                    if (_expiryController.text.isEmpty) {
                      PremiumSnackbar.show(
                        context,
                        'Please enter the expiry date',
                        isError: true,
                      );
                      return;
                    }
                    if (_nameController.text.trim().isEmpty) {
                      PremiumSnackbar.show(
                        context,
                        'Please enter the cardholder name',
                        isError: true,
                      );
                      return;
                    }
                    final detectedNetwork = CardUtils.getCardNetwork(
                      normalizedCardNumber,
                    );
                    final card = CardModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      cardNumber: normalizedCardNumber,
                      lastFour: normalizedCardNumber.length >= 4
                          ? normalizedCardNumber.substring(
                              normalizedCardNumber.length - 4,
                            )
                          : '0000',
                      expiryDate: _expiryController.text,
                      cardholderName: _nameController.text.trim(),
                      network: detectedNetwork,
                      colors: [
                        AppColors.primary.value,
                        const Color(0xFF6366F1).value,
                      ],
                    );
                    final success = await ref
                        .read(cardControllerProvider.notifier)
                        .addCard(card);
                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      PremiumSnackbar.show(context, l10n.cardAddedSuccess);
                    } else {
                      PremiumSnackbar.show(
                        context,
                        'Failed to save card. Please try again.',
                        isError: true,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
