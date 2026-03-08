import '../../../models/transaction_model.dart';

/// On-device fraud detection using a 5-factor weighted scoring model.
class FraudDetectionService {
  FraudDetectionService._();

  /// Score a transaction for fraud risk (0-100).
  static double scoreTransaction({
    required TransactionModel transaction,
    required List<TransactionModel> history,
    required double currentBalance,
  }) {
    if (history.isEmpty) return 15.0;

    double score = 0;

    // Factor 1: Amount deviation (30%)
    final avgAmount =
        history.map((t) => t.amount).reduce((a, b) => a + b) / history.length;
    final deviation =
        (transaction.amount - avgAmount).abs() /
        (avgAmount == 0 ? 1 : avgAmount);
    score += (deviation.clamp(0.0, 3.0) / 3.0) * 30;

    // Factor 2: Time anomaly (15%) — penalize 1-5 AM transactions
    final hour = transaction.timestamp.hour;
    if (hour >= 1 && hour <= 5) score += 15;

    // Factor 3: Velocity check (25%) — multiple txns in short period
    final recent = history
        .where(
          (t) =>
              transaction.timestamp.difference(t.timestamp).inMinutes.abs() < 5,
        )
        .length;
    score += (recent > 3 ? 25 : recent * 6).toDouble();

    // Factor 4: Category anomaly (15%) — never-used category gets penalty
    final usedCategories = history.map((t) => t.category).toSet();
    if (!usedCategories.contains(transaction.category)) score += 15;

    // Factor 5: Balance threshold (15%) — txn > 50% of balance
    if (currentBalance > 0 && transaction.amount / currentBalance > 0.5) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  /// Whether the score requires step-up authentication.
  static bool requiresStepUp(double score) => score >= 75;

  /// Risk level label.
  static String riskLevel(double score) {
    if (score < 30) return 'LOW';
    if (score < 75) return 'MEDIUM';
    return 'HIGH';
  }
}
