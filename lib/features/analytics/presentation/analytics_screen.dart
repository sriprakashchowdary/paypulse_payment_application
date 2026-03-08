import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/ai/services/ai_governance_service.dart';
import '../../../features/ai/services/pulse_score_calculator.dart';
import '../../../features/ai/services/subscription_detector_service.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_preferences_provider.dart';
import '../../../providers/wallet_provider.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  Widget _buildMonthBadge(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        DateFormat('MMM yyyy').format(DateTime.now()),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError(Object e) {
    return Center(child: Text('Error: $e'));
  }

  Widget _buildInsightsSection(
    BuildContext context,
    List<String> insights,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.aiInsights,
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        ...insights.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureFlags(BuildContext context, bool lock, bool roundUp) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FeatureChip(
          icon: Icons.shield_moon_rounded,
          label: lock ? 'Emergency Lock ON' : 'Emergency Lock OFF',
          active: lock,
        ),
        _FeatureChip(
          icon: Icons.savings_rounded,
          label: roundUp ? 'Round-Up ON' : 'Round-Up OFF',
          active: roundUp,
        ),
        _FeatureChip(
          icon: Icons.auto_awesome_rounded,
          label: 'Subscription AI',
          active: true,
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(
    BuildContext context,
    List<DetectedSubscription> subscriptions,
  ) {
    final theme = Theme.of(context);
    if (subscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(AppLocalizations.of(context)!.noRecurringPatterns),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            theme.cardColor.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: subscriptions.take(4).map((item) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: const Icon(
                Icons.repeat_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
            ),
            title: Text(item.merchant),
            subtitle: Text(
              '${item.frequency} • ${item.occurrences} cycles • ${(item.confidence * 100).toStringAsFixed(0)}% confidence',
            ),
            trailing: Text('₹${item.averageAmount.toStringAsFixed(0)}'),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final txnsAsync = ref.watch(transactionsStreamProvider);
    final user = ref.watch(userDocProvider).value;
    final appPrefs = ref.watch(appPreferencesProvider);
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.analytics),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: _buildMonthBadge(context, isDark)),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _glow(
                AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.16),
                280,
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _glow(
                AppColors.secondary.withValues(alpha: isDark ? 0.26 : 0.14),
                260,
              ),
            ),
            txnsAsync.when(
              loading: _buildLoading,
              error: (e, _) => _buildError(e),
              data: (txns) {
                final pulseScore = ref.watch(pulseScoreProvider);
                final data = _AnalyticsData.fromTransactions(
                  txns: txns,
                  uid: uid,
                  monthlyBudget: user?.monthlyBudget ?? 10000,
                  pulseScore: pulseScore,
                );
                final subscriptions =
                    SubscriptionDetectorService.detect(txns, uid);

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _buildFeatureFlags(
                      context,
                      appPrefs.emergencyLock,
                      appPrefs.roundUpSavings,
                    ),
                    const SizedBox(height: 12),
                    _BudgetCard(data: data),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: l10n.pulseScore,
                            value: data.pulseScore.toString(),
                            subtitle:
                                PulseScoreCalculator.label(data.pulseScore),
                            icon: Icons.favorite_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MetricCard(
                            title: l10n.prediction,
                            value: '₹${data.predicted.toStringAsFixed(0)}',
                            subtitle: l10n.estimatedSpend,
                            icon: Icons.insights_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.categoryBreakdown,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    _CategoryBreakdown(
                      entries: data.sortedCategories,
                      totalSpent: data.totalSpent,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.detectedSubscriptions,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    _buildSubscriptionSection(context, subscriptions),
                    const SizedBox(height: 18),
                    _buildInsightsSection(context, data.insights),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.full),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final _AnalyticsData data;

  const _BudgetCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final progress = data.monthlyBudget <= 0
        ? 0.0
        : (data.totalSpent / data.monthlyBudget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(Radii.xl),
        boxShadow: Shadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlyBudget,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${data.totalSpent.toStringAsFixed(0)} / ₹${data.monthlyBudget.toStringAsFixed(0)}',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            theme.cardColor.withValues(alpha: 0.76),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.dark ? [] : Shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final double totalSpent;

  const _CategoryBreakdown({required this.entries, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(AppLocalizations.of(context)!.noSpendingData),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            theme.cardColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: entries.take(5).map((entry) {
          final fraction = totalSpent <= 0 ? 0.0 : (entry.value / totalSpent);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text('₹${entry.value.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.full),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 7,
                    color: AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnalyticsData {
  final double monthlyBudget;
  final double totalSpent;
  final int pulseScore;
  final double predicted;
  final List<MapEntry<String, double>> sortedCategories;
  final List<String> insights;

  const _AnalyticsData({
    required this.monthlyBudget,
    required this.totalSpent,
    required this.pulseScore,
    required this.predicted,
    required this.sortedCategories,
    required this.insights,
  });

  factory _AnalyticsData.fromTransactions({
    required List<TransactionModel> txns,
    required String uid,
    required double monthlyBudget,
    required int pulseScore,
  }) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final monthTxns = txns.where((t) => t.timestamp.isAfter(firstDayOfMonth));
    final expenses = monthTxns.where((t) => !t.isCredit(uid)).toList();
    final totalSpent = expenses.fold<double>(0.0, (sum, t) => sum + t.amount);

    final categoryMap = <String, double>{};
    for (final tx in expenses) {
      categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
    }

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final predicted = AiGovernanceService.predictMonthlySpend(txns, uid);
    final insights = AiGovernanceService.generateInsights(
      sortedCategories,
      txns,
      uid,
    );

    return _AnalyticsData(
      monthlyBudget: monthlyBudget,
      totalSpent: totalSpent,
      pulseScore: pulseScore,
      predicted: predicted,
      sortedCategories: sortedCategories,
      insights: insights,
    );
  }
}
