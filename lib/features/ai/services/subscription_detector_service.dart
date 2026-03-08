import '../../../models/transaction_model.dart';

class DetectedSubscription {
  final String merchant;
  final double averageAmount;
  final int occurrences;
  final String frequency;
  final DateTime? nextDueDate;
  final double confidence;

  const DetectedSubscription({
    required this.merchant,
    required this.averageAmount,
    required this.occurrences,
    required this.frequency,
    required this.nextDueDate,
    required this.confidence,
  });
}

class SubscriptionDetectorService {
  SubscriptionDetectorService._();

  static List<DetectedSubscription> detect(
    List<TransactionModel> transactions,
    String uid,
  ) {
    final debits = transactions
        .where((tx) => tx.senderId == uid && tx.amount > 0)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final grouped = <String, List<TransactionModel>>{};
    for (final tx in debits) {
      final key = _merchantKey(tx);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final subscriptions = <DetectedSubscription>[];

    for (final entry in grouped.entries) {
      final txns = entry.value;
      if (txns.length < 2) continue;

      final intervals = <int>[];
      for (var i = 1; i < txns.length; i++) {
        intervals
            .add(txns[i].timestamp.difference(txns[i - 1].timestamp).inDays);
      }

      if (intervals.isEmpty) continue;

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final normalized = intervals
              .map((v) => (v - avgInterval).abs())
              .fold<double>(0.0, (sum, v) => sum + v) /
          intervals.length;

      final isWeekly = avgInterval >= 5 && avgInterval <= 10;
      final isMonthly = avgInterval >= 24 && avgInterval <= 36;
      if (!isWeekly && !isMonthly) continue;

      final avgAmount =
          txns.map((e) => e.amount).reduce((a, b) => a + b) / txns.length;
      final frequency = isMonthly ? 'Monthly' : 'Weekly';
      final confidence =
          (1 - (normalized / (avgInterval == 0 ? 1 : avgInterval)))
              .clamp(0.0, 1.0)
              .toDouble();

      final last = txns.last.timestamp;
      final nextDue = last.add(Duration(days: avgInterval.round()));

      subscriptions.add(
        DetectedSubscription(
          merchant: txns.last.title ?? entry.key,
          averageAmount: avgAmount,
          occurrences: txns.length,
          frequency: frequency,
          nextDueDate: nextDue,
          confidence: confidence,
        ),
      );
    }

    subscriptions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return subscriptions;
  }

  static String _merchantKey(TransactionModel tx) {
    final title = (tx.title ?? tx.category).toLowerCase().trim();
    if (title.isEmpty) return tx.category.toLowerCase();
    final sanitized = title
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.split(' ').take(2).join(' ');
  }
}
