import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal_model.dart';
import '../features/notifications/services/notification_service.dart';
import 'auth_provider.dart';

final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final uid = user?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('goals')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => GoalModel.fromFirestore(d)).toList());
});

final goalsControllerProvider = Provider((ref) => GoalsController(ref));

class GoalsController {
  final Ref _ref;
  GoalsController(this._ref);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Creates a new savings goal for the current user.
  Future<bool> addGoal(String title, double targetAmount) async {
    final uid = _ref.read(authControllerProvider.notifier).currentUid;
    if (uid == null) return false;

    try {
      final goal = GoalModel(
        id: '', // Firestore will generate the ID
        userId: uid,
        title: title.trim(),
        targetAmount: targetAmount,
        currentAmount: 0,
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      await _db.collection('goals').add(goal.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a goal by its Firestore document ID.
  Future<bool> deleteGoal(String goalId) async {
    final uid = _ref.read(authControllerProvider.notifier).currentUid;
    if (uid == null) return false;

    try {
      final goalRef = _db.collection('goals').doc(goalId);
      final snap = await goalRef.get();

      // Verify ownership before deleting
      if (!snap.exists) return false;
      final data = snap.data();
      if (data?['userId'] != uid) return false;

      await goalRef.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Adds progress (money) toward an existing goal.
  Future<void> addProgress(String goalId, double amount) async {
    final uid = _ref.read(authControllerProvider.notifier).currentUid;
    if (uid == null) return;

    final goalRef = _db.collection('goals').doc(goalId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(goalRef);
      if (!snap.exists) return;

      final goal = GoalModel.fromFirestore(snap);
      final newAmount = goal.currentAmount + amount;
      final newlyCompleted =
          !goal.isCompleted && newAmount >= goal.targetAmount;

      txn.update(goalRef, {
        'currentAmount': newAmount,
        'isCompleted': newlyCompleted || goal.isCompleted,
      });

      if (newlyCompleted) {
        // Trigger Notification
        _ref.read(notificationServiceProvider).sendNotification(
          recipientUid: uid,
          title: 'Goal Achieved! 🎉',
          body: 'Congratulations! You have completed your goal: ${goal.title}',
          data: {'type': 'success'},
        );
      }
    });
  }
}
