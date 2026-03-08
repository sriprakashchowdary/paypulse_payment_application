import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../shared/widgets/widgets.dart';

final historyFilterProvider = StateProvider<String>((ref) => 'All');
final searchQueryProvider = StateProvider<String>((ref) => '');

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  bool _matchesFilter(String filter, dynamic tx, String uid) {
    if (filter == 'Income') return tx.isCredit(uid);
    if (filter == 'Expense') return !tx.isCredit(uid);
    if (filter == 'Savings') {
      return tx.type.toLowerCase().contains('saving') ||
          tx.category.toLowerCase() == 'savings';
    }
    return true;
  }

  bool _matchesQuery(String query, dynamic tx) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final title = (tx.title ?? '').toLowerCase();
    final category = tx.category.toLowerCase();
    final amount = tx.amount.toStringAsFixed(0);
    return title.contains(q) || category.contains(q) || amount.contains(q);
  }

  List<dynamic> _applyFilters(
    List<dynamic> transactions,
    String filter,
    String query,
    String uid,
  ) {
    return transactions
        .where((tx) => _matchesFilter(filter, tx, uid))
        .where((tx) => _matchesQuery(query, tx))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final txnsAsync = ref.watch(transactionsStreamProvider);
    final filter = ref.watch(historyFilterProvider);
    final query = ref.watch(searchQueryProvider);
    final l10n = AppLocalizations.of(context)!;

    final filterItems = [
      {'label': l10n.all, 'value': 'All'},
      {'label': l10n.income, 'value': 'Income'},
      {'label': l10n.expense, 'value': 'Expense'},
      {'label': l10n.savings, 'value': 'Savings'},
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.history)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Radii.xl),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: isDark ? [] : Shadows.card,
                ),
                child: TextField(
                  onChanged: (val) =>
                      ref.read(searchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => ref
                                .read(searchQueryProvider.notifier)
                                .state = '',
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.03),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: filterItems
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(item['label']!),
                          selected: filter == item['value'],
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.16),
                          side: BorderSide(
                            color: filter == item['value']
                                ? AppColors.primary.withValues(alpha: 0.36)
                                : theme.dividerColor,
                          ),
                          labelStyle: TextStyle(
                            color: filter == item['value']
                                ? AppColors.primary
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: filter == item['value']
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            ref.read(historyFilterProvider.notifier).state =
                                item['value']!;
                          },
                        ),
                      ),
                    )
                    .toList(),
              ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: txnsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (txns) {
                  final filtered = _applyFilters(txns, filter, query, uid);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            color:
                                isDark ? Colors.white24 : AppColors.textMuted,
                            size: 44,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.noTransactionsFound,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TransactionCard(
                          title: tx.title ?? 'Transaction',
                          amount: tx.amount,
                          date: tx.timestamp,
                          isCredit: tx.isCredit(uid),
                          type: tx.type,
                          category: tx.category,
                        ).animate().fadeIn(delay: (index * 45).ms).slideY(
                              begin: 0.05,
                              end: 0,
                            ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
