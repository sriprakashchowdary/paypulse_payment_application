import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Transaction model with optimized indexing for real-time streaming.
/// Stored in root `transactions` collection for multi-user visibility.
class TransactionModel {
  final String id;
  final String? title; // Optional descriptive title
  final String senderId;
  final String receiverId;
  final double amount;
  final String category;
  final String type; // credit / debit
  final String status; // completed, pending, failed
  final DateTime timestamp;

  const TransactionModel({
    required this.id,
    this.title,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.category,
    required this.type,
    required this.status,
    required this.timestamp,
  });

  /// Helper to determine if transaction is a credit for a specific user
  bool isCredit(String uid) => type == 'credit' && receiverId == uid;

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Transaction document data is null');

      final d = data;
      return TransactionModel(
        id: doc.id,
        title: d['title'],
        senderId: d['senderId'] ?? '',
        receiverId: d['receiverId'] ?? '',
        amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
        category: d['category'] ?? 'Other',
        type: d['type'] ?? 'debit',
        status: d['status'] ?? 'completed',
        timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('[ERROR] TransactionModel.fromFirestore (ID: ${doc.id}): $e');
      debugPrint('$st');
      return TransactionModel(
        id: doc.id,
        senderId: '',
        receiverId: '',
        amount: 0.0,
        category: 'Error',
        type: 'debit',
        status: 'failed',
        timestamp: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'senderId': senderId,
        'receiverId': receiverId,
        'amount': amount,
        'category': category,
        'type': type,
        'status': status,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  TransactionModel copyWith({
    String? title,
    String? senderId,
    String? receiverId,
    double? amount,
    String? category,
    String? type,
    String? status,
    DateTime? timestamp,
  }) {
    return TransactionModel(
      id: id,
      title: title ?? this.title,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
