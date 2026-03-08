import 'package:cloud_firestore/cloud_firestore.dart';

/// User document stored at `users/{uid}` in Firestore.
/// Optimized with real-time wallet stats and device tracking.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final double walletBalance;
  final double monthlyBudget;
  final double savingsVault;
  final double pulseCredit;
  final int pulseScore;
  final List<String> goals;
  final String? deviceId;
  final bool isWalletActive;
  final String? walletPin;
  final double goldGrams;
  final double goldInvested;
  final double totalCashback;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.walletBalance = 0,
    this.monthlyBudget = 10000,
    this.savingsVault = 0,
    this.pulseCredit = 2000,
    this.pulseScore = 750,
    this.goals = const [],
    this.deviceId,
    this.isWalletActive = false,
    this.walletPin,
    this.goldGrams = 0,
    this.goldInvested = 0,
    this.totalCashback = 0,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'],
      photoUrl: d['photoUrl'],
      walletBalance: (d['walletBalance'] as num?)?.toDouble() ?? 0.0,
      monthlyBudget: (d['monthlyBudget'] as num?)?.toDouble() ?? 10000.0,
      savingsVault: (d['savingsVault'] as num?)?.toDouble() ?? 0.0,
      pulseCredit: (d['pulseCredit'] as num?)?.toDouble() ??
          2000.0, // Fallback for new/legacy users
      pulseScore: d['pulseScore'] as int? ?? 750,
      goals: List<String>.from(d['goals'] ?? []),
      deviceId: d['deviceId'],
      isWalletActive: d['isWalletActive'] as bool? ?? false,
      walletPin: d['walletPin'],
      goldGrams: (d['goldGrams'] as num?)?.toDouble() ?? 0.0,
      goldInvested: (d['goldInvested'] as num?)?.toDouble() ?? 0.0,
      totalCashback: (d['totalCashback'] as num?)?.toDouble() ?? 0.0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'walletBalance': walletBalance,
        'monthlyBudget': monthlyBudget,
        'savingsVault': savingsVault,
        'pulseCredit': pulseCredit,
        'pulseScore': pulseScore,
        'goals': goals,
        'deviceId': deviceId,
        'isWalletActive': isWalletActive,
        if (walletPin != null) 'walletPin': walletPin,
        'goldGrams': goldGrams,
        'goldInvested': goldInvested,
        'totalCashback': totalCashback,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    double? walletBalance,
    double? monthlyBudget,
    double? savingsVault,
    double? pulseCredit,
    int? pulseScore,
    List<String>? goals,
    String? deviceId,
    bool? isWalletActive,
    String? walletPin,
    double? goldGrams,
    double? goldInvested,
    double? totalCashback,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      walletBalance: walletBalance ?? this.walletBalance,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      savingsVault: savingsVault ?? this.savingsVault,
      pulseCredit: pulseCredit ?? this.pulseCredit,
      pulseScore: pulseScore ?? this.pulseScore,
      goals: goals ?? this.goals,
      deviceId: deviceId ?? this.deviceId,
      isWalletActive: isWalletActive ?? this.isWalletActive,
      walletPin: walletPin ?? this.walletPin,
      goldGrams: goldGrams ?? this.goldGrams,
      goldInvested: goldInvested ?? this.goldInvested,
      totalCashback: totalCashback ?? this.totalCashback,
      createdAt: createdAt,
    );
  }
}
