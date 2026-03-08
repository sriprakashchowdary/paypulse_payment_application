import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../services/gold_service.dart';

/// ══════════════════════════════════════════════════════════════
/// DIGITAL GOLD — Premium gold investment screen
/// ══════════════════════════════════════════════════════════════

class GoldScreen extends ConsumerStatefulWidget {
  const GoldScreen({super.key});

  @override
  ConsumerState<GoldScreen> createState() => _GoldScreenState();
}

class _GoldScreenState extends ConsumerState<GoldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  static final _currencyFmt = NumberFormat('#,##0.00');
  static final _simpleFmt = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priceAsync = ref.watch(goldPriceProvider);
    final historyAsync = ref.watch(goldHistoryProvider);

    final grams =
        ref.watch(userDocProvider.select((u) => u.value?.goldGrams ?? 0.0));
    final invested =
        ref.watch(userDocProvider.select((u) => u.value?.goldInvested ?? 0.0));
    final holding = GoldHolding(grams: grams, investedAmount: invested);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(goldPriceProvider);
            ref.invalidate(goldHistoryProvider);
            ref.invalidate(userDocProvider);
            await ref.read(goldPriceProvider.future);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────
              SliverToBoxAdapter(child: _buildAppBar(isDark)),

              // ── Gold Price Hero Card ─────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: priceAsync.when(
                    data: (price) => _GoldHeroCard(
                      price: price,
                      holding: holding,
                      isDark: isDark,
                      shimmerCtrl: _shimmerCtrl,
                    ),
                    loading: () => _LoadingCard(isDark: isDark),
                    error: (_, __) => _ErrorCard(isDark: isDark),
                  ),
                ),
              ),

              // ── Quick Buy/Sell ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildActions(isDark, priceAsync),
                ),
              ),

              // ── Price Chart ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: historyAsync.when(
                    data: (data) => _PriceChart(data: data, isDark: isDark),
                    loading: () => _ChartPlaceholder(isDark: isDark),
                    error: (_, __) => _ChartPlaceholder(isDark: isDark),
                  ),
                ),
              ),

              // ── Holdings breakdown ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: priceAsync.when(
                    data: (price) => _HoldingsCard(
                        holding: holding, price: price, isDark: isDark),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ── Info tiles ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: _buildInfoSection(isDark),
                ).animate().fadeIn(delay: 800.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Gold',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '24K Pure Gold • 99.5% Purity',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFF5D060)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Color(0xFF5D4200)),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5D4200),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark, AsyncValue<GoldPrice> priceAsync) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Buy Gold',
            icon: Icons.add_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFF5D060)],
            ),
            textColor: const Color(0xFF5D4200),
            onTap: () => _showBuySellSheet(context, isDark, true),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ActionButton(
            label: 'Sell Gold',
            icon: Icons.remove_rounded,
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2D2D2D), const Color(0xFF3D3D3D)]
                  : [Colors.white, const Color(0xFFF8F8F8)],
            ),
            textColor: isDark ? Colors.white : AppColors.textPrimary,
            borderColor: isDark ? AppColors.borderDark : AppColors.border,
            onTap: () => _showBuySellSheet(context, isDark, false),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHY DIGITAL GOLD?',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white38 : AppColors.textMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        _InfoTile(
          icon: Icons.security_rounded,
          title: 'Bank-Grade Security',
          subtitle: 'Insured vaults with 24/7 monitoring',
          color: AppColors.primary,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.bolt_rounded,
          title: 'Instant Buy & Sell',
          subtitle: 'Real-time pricing, zero wait times',
          color: const Color(0xFFD4AF37),
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.savings_rounded,
          title: 'Start from ₹10',
          subtitle: 'Buy fractional gold from just ₹10',
          color: AppColors.success,
          isDark: isDark,
        ),
      ],
    );
  }

  void _showBuySellSheet(BuildContext context, bool isDark, bool isBuy) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BuySellSheet(key: UniqueKey(), isBuy: isBuy, isDark: isDark);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HERO CARD — glassmorphic gold price display
// ══════════════════════════════════════════════════════════════

class _GoldHeroCard extends StatelessWidget {
  final GoldPrice price;
  final GoldHolding holding;
  final bool isDark;
  final AnimationController shimmerCtrl;

  const _GoldHeroCard({
    required this.price,
    required this.holding,
    required this.isDark,
    required this.shimmerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = _GoldScreenState._currencyFmt;
    final currentValue = holding.currentValue(price.pricePerGram);
    final pnl = holding.profitLoss(price.pricePerGram);

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.xxl),
      child: Stack(
        children: [
          // Background gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🥇',
                          style: TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gold Spot Price',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₹${currencyFmt.format(price.pricePerGram)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  ' /gm',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Change badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: price.change24h >= 0
                            ? AppColors.success.withValues(alpha: 0.2)
                            : AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            price.change24h >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: price.change24h >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${price.change24h >= 0 ? '+' : ''}${price.change24h.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: price.change24h >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 16),

                // Holdings
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Your Gold',
                        value: '${holding.grams.toStringAsFixed(3)} gm',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroStat(
                        label: 'Current Value',
                        value: '₹${currencyFmt.format(currentValue)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: pnl >= 0
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pnl >= 0 ? '+' : ''}₹${_GoldScreenState._simpleFmt.format(pnl.abs())}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: pnl >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Glossy circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRICE CHART — 30 day line chart
// ══════════════════════════════════════════════════════════════

class _PriceChart extends StatelessWidget {
  final List<Map<String, double>> data;
  final bool isDark;
  const _PriceChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final spots = data.map((d) => FlSpot(d['day']!, d['price']!)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: isDark ? [] : Shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Price Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '30 DAYS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '₹${s.y.toStringAsFixed(0)}/gm',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF5D060)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFD4AF37).withValues(alpha: 0.25),
                          const Color(0xFFD4AF37).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HOLDINGS CARD
// ══════════════════════════════════════════════════════════════

class _HoldingsCard extends StatelessWidget {
  final GoldHolding holding;
  final GoldPrice price;
  final bool isDark;
  const _HoldingsCard({
    required this.holding,
    required this.price,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final simpleFmt = _GoldScreenState._simpleFmt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: isDark ? [] : Shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PORTFOLIO BREAKDOWN',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : AppColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _row('Gold Held', '${holding.grams.toStringAsFixed(4)} gm', isDark),
          _row('Invested Amount',
              '₹${simpleFmt.format(holding.investedAmount)}', isDark),
          _row(
              'Current Value',
              '₹${simpleFmt.format(holding.currentValue(price.pricePerGram))}',
              isDark),
          _row(
              'Avg. Buy Price',
              '₹${holding.grams > 0 ? simpleFmt.format(holding.investedAmount / holding.grams) : '0'}',
              isDark),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.border,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit / Loss',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                '${holding.profitLoss(price.pricePerGram) >= 0 ? '+' : ''}₹${simpleFmt.format(holding.profitLoss(price.pricePerGram))}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: holding.profitLoss(price.pricePerGram) >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ACTION BUTTON
// ══════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.textColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// INFO TILE
// ══════════════════════════════════════════════════════════════

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BUY/SELL BOTTOM SHEET
// ══════════════════════════════════════════════════════════════

class _BuySellSheet extends ConsumerStatefulWidget {
  final bool isBuy;
  final bool isDark;
  const _BuySellSheet({super.key, required this.isBuy, required this.isDark});

  @override
  ConsumerState<_BuySellSheet> createState() => _BuySellSheetState();
}

class _BuySellSheetState extends ConsumerState<_BuySellSheet> {
  final _amountCtrl = TextEditingController();
  int _selectedQuick = -1;
  final _quickAmounts = [500, 1000, 2000, 5000];
  bool _isSuccess = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isBuy = widget.isBuy;
    final accentColor = isBuy ? const Color(0xFFD4AF37) : AppColors.error;

    final priceAsync = ref.watch(goldPriceProvider);
    final controllerState = ref.watch(goldControllerProvider);
    final user = ref.watch(userDocProvider).value;

    if (_isSuccess) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 50),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                ),
                const SizedBox(height: 24),
                Text(
                  isBuy ? 'Purchase Successful!' : 'Sell Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
              ],
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              32 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                  : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  isBuy ? 'Buy Gold' : 'Sell Gold',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isBuy
                      ? 'Enter amount in ₹ to purchase gold'
                      : 'Enter grams to sell from your vault',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                if (user != null)
                  Text(
                    isBuy
                        ? 'Available: ₹${NumberFormat('#,##0.00').format(user.walletBalance)}'
                        : 'Available: ${user.goldGrams.toStringAsFixed(4)} gm',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isBuy ? AppColors.primary : const Color(0xFFD4AF37),
                    ),
                  ),
                const SizedBox(height: 28),

                // Amount field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: isBuy ? '₹ 0' : '0.00 gm',
                      hintStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white24 : AppColors.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick amounts
                if (isBuy)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_quickAmounts.length, (i) {
                      final active = _selectedQuick == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedQuick = i;
                            _amountCtrl.text = '${_quickAmounts[i]}';
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? accentColor.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFF8F9FA)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? accentColor
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.border),
                            ),
                          ),
                          child: Text(
                            '₹${_quickAmounts[i]}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? accentColor
                                  : (isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }),
                  )
                else if (user != null && user.goldGrams > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSellQuickButton(
                        label: 'Sell 50%',
                        value: user.goldGrams * 0.5,
                        accentColor: accentColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _buildSellQuickButton(
                        label: 'Sell All',
                        value: user.goldGrams,
                        accentColor: accentColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                const SizedBox(height: 28),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: priceAsync.when(
                    data: (price) => ElevatedButton(
                      onPressed: controllerState.isLoading
                          ? null
                          : () async {
                              final input = _amountCtrl.text
                                  .replaceAll('₹', '')
                                  .replaceAll(' gm', '')
                                  .trim();
                              final val = double.tryParse(input);

                              if (val == null || val <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please enter a valid amount')),
                                );
                                return;
                              }

                              HapticFeedback.heavyImpact();

                              final navigator = Navigator.of(context);

                              try {
                                if (isBuy) {
                                  await ref
                                      .read(goldControllerProvider.notifier)
                                      .buyGold(val, price.pricePerGram);
                                } else {
                                  await ref
                                      .read(goldControllerProvider.notifier)
                                      .sellGold(val, price.pricePerGram);
                                }

                                if (!mounted) return;

                                setState(() => _isSuccess = true);
                                HapticFeedback.heavyImpact();
                                Future.delayed(
                                    const Duration(milliseconds: 2000), () {
                                  if (mounted) navigator.pop();
                                });
                              } catch (e) {
                                if (!mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    title: Text(
                                      'Transaction Failed',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    content: Text(
                                      e
                                          .toString()
                                          .replaceAll('Exception: ', ''),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('OK',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: controllerState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isBuy ? 'Buy Now' : 'Sell Now',
                              style: TextStyle(
                                color: isBuy
                                    ? const Color(0xFF5D4200)
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Price unavailable')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSellQuickButton({
    required String label,
    required double value,
    required Color accentColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // Format value without trailing zero noise. E.g "1.5200" -> "1.52"
          String textVal = value.toStringAsFixed(4);
          if (textVal.contains('.')) {
            textVal = textVal.replaceAll(RegExp(r'0*$'), '');
            textVal = textVal.replaceAll(RegExp(r'\.$'), '');
          }
          _amountCtrl.text = textVal;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PLACEHOLDER WIDGETS
// ══════════════════════════════════════════════════════════════

class _LoadingCard extends StatelessWidget {
  final bool isDark;
  const _LoadingCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(Radii.xxl),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4AF37),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final bool isDark;
  const _ErrorCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(Radii.xxl),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Text(
          'Unable to fetch gold price. Pull to refresh.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  final bool isDark;
  const _ChartPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4AF37),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
