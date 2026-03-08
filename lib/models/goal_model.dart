import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final bool isCompleted;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      targetAmount: (d['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (d['currentAmount'] as num?)?.toDouble() ?? 0,
      isCompleted: d['isCompleted'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'isCompleted': isCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
