import '../../../models/transaction_model.dart';

/// Financial health score calculator (Pulse Score: 300-900).
class PulseScoreCalculator {
  PulseScoreCalculator._();

  /// Calculate Pulse Score from transaction history and balances.
  static int calculate({
    required List<TransactionModel> transactions,
    required double balance,
    required double savingsVault,
    required String uid,
  }) {
    if (transactions.isEmpty) return 750; // default for new users

    double rawScore = 0;

    // 1. Savings rate (30%)
    final totalIncome = transactions
        .where((t) => t.isCredit(uid))
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isCredit(uid))
        .fold(0.0, (s, t) => s + t.amount);
    final savingsRate =
        totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0.0;
    rawScore += (savingsRate.clamp(-0.5, 0.5) + 0.5) * 30;

    // 2. Spending consistency (25%)
    final amounts = transactions
        .where((t) => !t.isCredit(uid))
        .map((t) => t.amount)
        .toList();
    if (amounts.length > 1) {
      final mean = amounts.reduce((a, b) => a + b) / amounts.length.toDouble();
      final variance =
          amounts.map((a) => (a - mean) * (a - mean)).reduce((a, b) => a + b) /
              amounts.length.toDouble();
      final cv = mean > 0.0
          ? (variance > 0.0 ? (variance / (mean * mean)) : 0.0)
          : 1.0;
      rawScore += ((1 - cv.clamp(0.0, 1.0)) * 25);
    } else {
      rawScore += 12;
    }

    // 3. Bill payments (20%)
    final billCount = transactions.where((t) => t.category == 'Bills').length;
    rawScore += (billCount.clamp(0, 5) / 5) * 20;

    // 4. Category diversity (15%)
    final categories = transactions.map((t) => t.category).toSet().length;
    rawScore += (categories.clamp(0, 6) / 6) * 15;

    // 5. Account activity (10%)
    final daysSinceLastTxn =
        DateTime.now().difference(transactions.first.timestamp).inDays;
    rawScore += ((1 - (daysSinceLastTxn / 30).clamp(0.0, 1.0)) * 10);

    // Map 0-100 → 300-900
    return (300 + (rawScore / 100 * 600)).round().clamp(300, 900);
  }

  /// Score label.
  static String label(int score) {
    if (score >= 800) return 'Excellent';
    if (score >= 700) return 'Good';
    if (score >= 600) return 'Fair';
    if (score >= 500) return 'Below Average';
    return 'Poor';
  }
}
