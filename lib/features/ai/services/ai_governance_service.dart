import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/transaction_model.dart';
import '../../notifications/services/notification_service.dart';
import 'ai_categorization_service.dart';

class AiGovernanceService {
  AiGovernanceService._();

  /// Rule 1: Auto Categorize Expense
  static String getCategory(String title, String? manualCategory) {
    if (manualCategory != null && manualCategory != 'Other') {
      return manualCategory;
    }
    return AiCategorizationService.categorize(title);
  }

  /// Rule 2: Budget Monitoring (80% alert)
  static Future<void> checkBudgetAlert({
    required String uid,
    required double monthlyBudget,
    required List<TransactionModel> history,
    required FirebaseFirestore db,
    required NotificationService notificationService,
  }) async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);

    final spent = history
        .where((t) => t.timestamp.isAfter(firstDay) && t.senderId == uid)
        .fold(0.0, (s, t) => s + t.amount);

    if (spent >= monthlyBudget * 0.8) {
      // Create alert if not already created this month
      final alertId = 'budget_80_${uid}_${now.month}_${now.year}';
      final alertRef = db.collection('alerts').doc(alertId);

      final doc = await alertRef.get();
      if (!doc.exists) {
        await alertRef.set({
          'userId': uid,
          'message':
              'Budget Warning: You have reached 80% of your ₹${monthlyBudget.toInt()} monthly limit.',
          'alertType': 'warning',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Trigger Push Notification
        await notificationService.sendNotification(
          recipientUid: uid,
          title: 'Budget Alert ⚠️',
          body:
              'You have reached 80% of your ₹${monthlyBudget.toInt()} monthly limit.',
          data: {'type': 'warning'},
        );
      }
    }
  }

  /// Rule 3: Fraud Detection Rules
  static Future<void> detectFraud({
    required String uid,
    required TransactionModel transaction,
    required List<TransactionModel> history,
    required FirebaseFirestore db,
    required NotificationService notificationService,
    String? currentDeviceId,
  }) async {
    final alerts = <String>[];

    // Rule 3.1: Large Transaction (> 10,000)
    if (transaction.amount > 10000) {
      alerts.add('Large transaction of ₹${transaction.amount} detected.');
    }

    // Rule 3.2: Velocity Check (3 txns in 1 min)
    final oneMinAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final recentCount =
        history.where((t) => t.timestamp.isAfter(oneMinAgo)).length;
    if (recentCount >= 2) {
      // current + 2 previous = 3
      alerts.add('High transaction frequency detected (3+ in 1 minute).');
    }

    // Rule 3.3: Device Change (Simplified check)
    // In a real app, we'd compare against stored user deviceIds

    for (var msg in alerts) {
      await db.collection('alerts').add({
        'userId': uid,
        'message': 'Security Alert: $msg',
        'alertType': 'error',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Trigger Push Notification
      await notificationService.sendNotification(
        recipientUid: uid,
        title: 'Security Alert 🚨',
        body: msg,
        data: {'type': 'error'},
      );
    }
  }

  /// Rule 4: Monthly Prediction
  static double predictMonthlySpend(
    List<TransactionModel> history,
    String uid,
  ) {
    if (history.isEmpty) return 0;

    final firstTxnDate = history.last.timestamp;
    final days = DateTime.now().difference(firstTxnDate).inDays + 1;
    final totalSpent = history
        .where((t) => t.senderId == uid)
        .fold(0.0, (s, t) => s + t.amount);

    final avgDaily = totalSpent / days;
    return avgDaily * 30;
  }

  /// Rule 5: Generate Insights
  static List<String> generateInsights(
    List<MapEntry<String, double>> categories,
    List<TransactionModel> allTxns,
    String uid,
  ) {
    if (categories.isEmpty) return ['Start transacting to see AI insights.'];
    final topCat = categories.first;
    return [
      'Your highest spend this month is on ${topCat.key} (₹${topCat.value.toInt()}).',
      'Based on your velocity, try cutting back on ${topCat.key} to save more next week.',
    ];
  }
}
