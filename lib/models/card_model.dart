import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CardNetwork {
  visa('Visa'),
  mastercard('Mastercard'),
  rupay('Rupay'),
  amex('American Express'),
  discover('Discover'),
  unknown('Unknown');

  final String label;
  const CardNetwork(this.label);
}

class CardModel {
  final String id;
  final String cardNumber; // Full number or encrypted
  final String lastFour;
  final String expiryDate;
  final String cardholderName;
  final CardNetwork network;
  final List<int> colors; // List of ARGB values
  final bool isFrozen;
  final bool
      isDetailsVisible; // App-only state, not usually saved to DB, but kept here for simplicity
  final double monthlyLimit;
  final double monthlySpent;

  CardModel({
    required this.id,
    required this.cardNumber,
    required this.lastFour,
    required this.expiryDate,
    required this.cardholderName,
    required this.network,
    this.colors = const [0xFF1E293B, 0xFF0F172A],
    this.isFrozen = false,
    this.isDetailsVisible = false,
    this.monthlyLimit = 200000.0,
    this.monthlySpent = 0.0,
  });

  factory CardModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) throw Exception('Card document data is null');
      final d = data;

      // Ensure we always have at least 2 colors for LinearGradient
      final dynamic rawColors = d['colors'];
      List<int> validatedColors = [];
      if (rawColors is List) {
        validatedColors = rawColors.map((e) => (e as num).toInt()).toList();
      }

      if (validatedColors.length < 2) {
        validatedColors = [0xFF1E293B, 0xFF0F172A]; // Default navy gradient
      }

      return CardModel(
        id: doc.id,
        cardNumber: d['cardNumber'] ?? '',
        lastFour: d['lastFour'] ?? '',
        expiryDate: d['expiryDate'] ?? '',
        cardholderName: d['cardholderName'] ?? '',
        network: CardNetwork.values.firstWhere(
          (e) => e.name == d['network'],
          orElse: () => CardNetwork.unknown,
        ),
        colors: validatedColors,
        isFrozen: d['isFrozen'] ?? false,
        isDetailsVisible: d['isDetailsVisible'] ?? false,
        monthlyLimit: (d['monthlyLimit'] as num?)?.toDouble() ?? 200000.0,
        monthlySpent: (d['monthlySpent'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e, st) {
      debugPrint('[ERROR] CardModel.fromFirestore (ID: ${doc.id}): $e');
      debugPrint('$st');
      return CardModel(
        id: doc.id,
        cardNumber: '**** **** **** 0000',
        lastFour: '0000',
        expiryDate: '01/01',
        cardholderName: 'Unknown',
        network: CardNetwork.unknown,
      );
    }
  }

  Map<String, dynamic> toFirestore() => {
        'cardNumber': cardNumber,
        'lastFour': lastFour,
        'expiryDate': expiryDate,
        'cardholderName': cardholderName,
        'network': network.name,
        'colors': colors,
        'isFrozen': isFrozen,
        'isDetailsVisible': isDetailsVisible,
        'monthlyLimit': monthlyLimit,
        'monthlySpent': monthlySpent,
      };
}
