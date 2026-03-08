import 'package:cloud_firestore/cloud_firestore.dart';

/// Alert/Notification model for real-time user updates.
class AlertModel {
  final String id;
  final String userId;
  final String message;
  final String alertType; // info, warning, error, success
  final DateTime createdAt;
  final bool isRead;

  const AlertModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.alertType,
    required this.createdAt,
    this.isRead = false,
  });

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AlertModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      message: d['message'] ?? '',
      alertType: d['alertType'] ?? 'info',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'message': message,
    'alertType': alertType,
    'createdAt': Timestamp.fromDate(createdAt),
    'isRead': isRead,
  };

  AlertModel copyWith({String? message, String? alertType, bool? isRead}) {
    return AlertModel(
      id: id,
      userId: userId,
      message: message ?? this.message,
      alertType: alertType ?? this.alertType,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
