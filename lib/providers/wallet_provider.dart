import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import '../features/ai/services/ai_governance_service.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/ai/services/pulse_score_calculator.dart';
import 'auth_provider.dart';
import 'app_preferences_provider.dart';

/// Proxy for the user's wallet stats (stored in UserModel).
final walletStreamProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) {
        debugPrint('[DEBUG] walletStreamProvider: user is null (signed out)');
        return Stream.value(null);
      }
      debugPrint(
          '[DEBUG] walletStreamProvider: user found (UID: ${user.uid}), listening to doc...');
      return ref.read(userDocProvider.stream);
    },
    loading: () {
      debugPrint('[DEBUG] walletStreamProvider: auth state is loading...');
      return const Stream.empty();
    },
    error: (e, st) {
      debugPrint('[ERROR] walletStreamProvider auth error: $e');
      return Stream.error(e, st);
    },
  );
});

/// Provider for random number generation.
final randomProvider =
    Provider((ref) => DateTime.now().millisecond); // Simplified seed

/// Streams the user's transactions (where they are sender or receiver).
/// Uses two separate queries merged in memory for high reliability.
final _sentTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return ref
      .read(firestoreProvider)
      .collection('transactions')
      .where('senderId', isEqualTo: uid)
      .limit(50)
      .snapshots(includeMetadataChanges: true)
      .map((snap) =>
          snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList());
});

final _receivedTransactionsProvider =
    StreamProvider<List<TransactionModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return ref
      .read(firestoreProvider)
      .collection('transactions')
      .where('receiverId', isEqualTo: uid)
      .limit(50)
      .snapshots(includeMetadataChanges: true)
      .map((snap) =>
          snap.docs.map((d) => TransactionModel.fromFirestore(d)).toList());
});

/// Watches both sent and received transactions and merges them in memory.
/// This behaves exactly like a StreamProvider from the UI's perspective (returns AsyncValue).
final transactionsStreamProvider =
    Provider<AsyncValue<List<TransactionModel>>>((ref) {
  final sentAsync = ref.watch(_sentTransactionsProvider);
  final receivedAsync = ref.watch(_receivedTransactionsProvider);

  // If either stream has an error, propagate it
  if (sentAsync.hasError)
    return AsyncValue.error(sentAsync.error!, sentAsync.stackTrace!);
  if (receivedAsync.hasError)
    return AsyncValue.error(receivedAsync.error!, receivedAsync.stackTrace!);

  // If both are loading, we are loading
  if (sentAsync.isLoading && receivedAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Once at least one has data (or both), we can merge what we have
  final sent = sentAsync.value ?? [];
  final received = receivedAsync.value ?? [];
  final merged = [...sent, ...received];

  final seen = <String>{};
  final unique = merged.where((tx) => seen.add(tx.id)).toList();
  unique.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return AsyncValue.data(unique.take(100).toList());
});

/// Provider for the real-time calculated Pulse Score.
final pulseScoreProvider = Provider<int>((ref) {
  final txns = ref.watch(transactionsStreamProvider).value ?? [];
  final user = ref.watch(userDocProvider).value;
  final uid = ref.watch(authStateProvider).value?.uid ?? '';

  if (user == null) return 750;

  return PulseScoreCalculator.calculate(
    transactions: txns,
    balance: user.walletBalance,
    savingsVault: user.savingsVault,
    uid: uid,
  );
});

/// Streams real-time alerts for the user.
final alertsStreamProvider = StreamProvider<List<AlertModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final uid = user?.uid;
  if (uid == null) return Stream.value([]);

  return ref
      .read(firestoreProvider)
      .collection('alerts')
      .where('userId', isEqualTo: uid)
      // No .orderBy() here — avoids requiring a composite index.
      .limit(20)
      .snapshots()
      .map((snap) {
    final docs = snap.docs.map((d) => AlertModel.fromFirestore(d)).toList();
    // Sort in memory — newest first
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  });
});

/// Wallet operations controller — optimized for the new schema.
final walletControllerProvider =
    StateNotifierProvider<WalletController, AsyncValue<void>>((ref) {
  return WalletController(ref);
});

class WalletController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  WalletController(this._ref) : super(const AsyncData(null));

  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  String? get _uid => _ref.read(authControllerProvider.notifier).currentUid;

  DocumentReference get _userRef => _db.collection('users').doc(_uid);
  CollectionReference get _txnRef => _db.collection('transactions');

  double _calculateRoundUp(double amount) {
    final ceil = amount.ceilToDouble();
    final roundUp = ceil - amount;
    if (roundUp <= 0 || roundUp >= 1) return 0.0;
    return double.parse(roundUp.toStringAsFixed(2));
  }

  /// Add funds to wallet (simulating a top-up).
  Future<bool> addFunds(double amount, String method) async {
    if (_uid == null) return false;
    state = const AsyncLoading();
    try {
      final batch = _db.batch();

      // Update user balance
      batch.update(_userRef, {'walletBalance': FieldValue.increment(amount)});

      // Record transaction
      final txnDoc = _txnRef.doc();
      batch.set(txnDoc, {
        'title': 'Wallet Top-up ($method)',
        'senderId': 'system',
        'receiverId': _uid,
        'amount': amount,
        'category': 'Transfers',
        'type': 'credit',
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Deduct funds (Transfer/Payment).
  Future<bool> deductFunds(
    double amount,
    String title, {
    String receiverId = 'merchant_id', // default for payments
    String category = 'Other',
  }) async {
    if (_uid == null) return false;
    state = const AsyncLoading();
    try {
      final appPrefs = _ref.read(appPreferencesProvider);
      if (appPrefs.emergencyLock) {
        throw Exception(
            'Emergency lock is enabled. Outgoing payments are paused.');
      }

      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(_userRef);
        final user = UserModel.fromFirestore(userSnap);

        final roundUp = appPrefs.roundUpSavings ? _calculateRoundUp(amount) : 0;
        final totalDebit = amount + roundUp;

        if (user.walletBalance < totalDebit) {
          throw Exception('Insufficient balance');
        }

        // Deduct from sender
        txn.update(_userRef, {
          'walletBalance': FieldValue.increment(-totalDebit),
          if (roundUp > 0) 'savingsVault': FieldValue.increment(roundUp),
        });

        // Credit receiver if it's a real user (not system/merchant placeholder)
        final isRealReceiver = receiverId != 'merchant_id' &&
            receiverId != 'system' &&
            receiverId != _uid;
        if (isRealReceiver) {
          final receiverRef = _db.collection('users').doc(receiverId);
          txn.update(receiverRef, {
            'walletBalance': FieldValue.increment(amount),
          });
        }

        // Create transaction model for AI checks
        final txnDoc = _txnRef.doc();
        final newTxn = TransactionModel(
          id: txnDoc.id,
          title: title,
          senderId: _uid!,
          receiverId: receiverId,
          amount: amount,
          category: AiGovernanceService.getCategory(title, category),
          type: 'debit',
          status: 'completed',
          timestamp: DateTime.now(),
        );

        // Record transaction
        txn.set(txnDoc, {
          ...newTxn.toFirestore(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (roundUp > 0) {
          final savingsTxnDoc = _txnRef.doc();
          txn.set(savingsTxnDoc, {
            'title': 'Round-up Auto Save',
            'senderId': _uid,
            'receiverId': _uid,
            'amount': roundUp,
            'category': 'Savings',
            'type': 'savings',
            'status': 'completed',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // 3. Post-transaction AI Governance (Async)
        _runAiGovernance(newTxn, user.monthlyBudget);

        // 4. Award Cashback (Random 1-10 INR)
        _awardCashback(txn);
      });
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Award a random ₹1-10 cashback to the user.
  void _awardCashback(Transaction txn) {
    if (_uid == null) return;

    final cashback = (DateTime.now().millisecond % 10 + 1).toDouble();

    // Update user stats
    txn.update(_userRef, {
      'walletBalance': FieldValue.increment(cashback),
      'totalCashback': FieldValue.increment(cashback),
    });

    // Record cashback transaction
    final rewardDoc = _txnRef.doc();
    txn.set(rewardDoc, {
      'title': 'Cashback Reward',
      'senderId': 'system',
      'receiverId': _uid,
      'amount': cashback,
      'category': 'Rewards',
      'type': 'credit',
      'status': 'completed',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Transfer funds to another user by email or mobile number.
  Future<bool> transferFunds(double amount, String receiverContact) async {
    if (_uid == null) return false;
    state = const AsyncLoading();
    try {
      final appPrefs = _ref.read(appPreferencesProvider);
      if (appPrefs.emergencyLock) {
        throw Exception(
            'Emergency lock is enabled. Outgoing transfers are paused.');
      }

      // 1. Search for receiver by email first, then phone
      QuerySnapshot<Map<String, dynamic>> receiverQuery = await _db
          .collection('users')
          .where('email', isEqualTo: receiverContact.trim())
          .limit(1)
          .get();

      if (receiverQuery.docs.isEmpty) {
        receiverQuery = await _db
            .collection('users')
            .where('phone', isEqualTo: receiverContact.trim())
            .limit(1)
            .get();
      }

      if (receiverQuery.docs.isEmpty) {
        throw Exception(
            'User doesn\'t have an account registered with this contact');
      }

      final receiverDoc = receiverQuery.docs.first;
      final receiverData = receiverDoc.data();
      final receiverId = receiverDoc.id;
      final receiverRef = _db.collection('users').doc(receiverId);
      final receiverName = receiverData['name'] ?? receiverContact;

      if (receiverData['isWalletActive'] != true) {
        throw Exception('User doesn\'t have an active wallet');
      }

      if (_uid == receiverId) {
        throw Exception('Cannot send money to yourself');
      }

      // 2. Perform atomic transfer using Firestore transaction
      late TransactionModel debitTxn;
      late double senderBudget;

      await _db.runTransaction((txn) async {
        // Read sender's current balance inside the transaction
        final senderSnap = await txn.get(_userRef);
        final sender = UserModel.fromFirestore(senderSnap);

        final roundUp = appPrefs.roundUpSavings ? _calculateRoundUp(amount) : 0;
        final totalDebit = amount + roundUp;

        if (sender.walletBalance < totalDebit) {
          throw Exception('Insufficient balance');
        }

        senderBudget = sender.monthlyBudget;

        // Deduct from sender
        txn.update(_userRef, {
          'walletBalance': FieldValue.increment(-totalDebit),
          if (roundUp > 0) 'savingsVault': FieldValue.increment(roundUp),
        });

        // Add to receiver
        txn.update(receiverRef, {
          'walletBalance': FieldValue.increment(amount),
        });

        // Create DEBIT transaction for Sender's History
        final debitDoc = _txnRef.doc();
        debitTxn = TransactionModel(
          id: debitDoc.id,
          title: 'Sent to $receiverName',
          senderId: _uid!,
          receiverId: receiverId,
          amount: amount,
          category: 'Transfers',
          type: 'debit',
          status: 'completed',
          timestamp: DateTime.now(),
        );

        txn.set(debitDoc, {
          ...debitTxn.toFirestore(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Create CREDIT transaction for Receiver's History
        final creditDoc = _txnRef.doc();
        txn.set(creditDoc, {
          'title': 'Received from ${sender.name}',
          'senderId': _uid,
          'receiverId': receiverId,
          'amount': amount,
          'category': 'Transfers',
          'type': 'credit',
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (roundUp > 0) {
          final savingsTxnDoc = _txnRef.doc();
          txn.set(savingsTxnDoc, {
            'title': 'Round-up Auto Save',
            'senderId': _uid,
            'receiverId': _uid,
            'amount': roundUp,
            'category': 'Savings',
            'type': 'savings',
            'status': 'completed',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        // 3. Award Cashback (Random 1-10 INR)
        _awardCashback(txn);
      });

      // 3. Post-transaction AI Governance (outside txn — non-blocking)
      _runAiGovernance(debitTxn, senderBudget);

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  static const MAX_CREDIT = 2000.0;

  /// Withdraw money from Pulse Credit line into Wallet.
  Future<bool> withdrawCredit(double amount) async {
    if (_uid == null) return false;
    state = const AsyncLoading();
    try {
      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(_userRef);
        final user = UserModel.fromFirestore(userSnap);

        if (user.pulseCredit < amount) {
          throw Exception('Insufficient Credit Limit');
        }

        // Add to wallet, deduct from credit
        txn.update(_userRef, {
          'walletBalance': FieldValue.increment(amount),
          'pulseCredit': FieldValue.increment(-amount),
        });

        // Record transaction
        final txnDoc = _txnRef.doc();
        txn.set(txnDoc, {
          'title': 'Credit Withdrawal',
          'senderId': 'system',
          'receiverId': _uid,
          'amount': amount,
          'category': 'Rewards', // Using rewards/transfers for credit
          'type': 'credit',
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Repay Pulse Credit from Wallet.
  Future<bool> repayCredit(double amount) async {
    if (_uid == null) return false;
    state = const AsyncLoading();
    try {
      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(_userRef);
        final user = UserModel.fromFirestore(userSnap);

        if (user.walletBalance < amount) {
          throw Exception('Insufficient Wallet Balance');
        }

        final usedCredit = MAX_CREDIT - user.pulseCredit;
        if (amount > usedCredit) {
          throw Exception('Repayment exceeds used credit');
        }

        // Deduct from wallet, add back to credit
        txn.update(_userRef, {
          'walletBalance': FieldValue.increment(-amount),
          'pulseCredit': FieldValue.increment(amount),
        });

        // Record transaction
        final txnDoc = _txnRef.doc();
        txn.set(txnDoc, {
          'title': 'Credit Repayment',
          'senderId': _uid,
          'receiverId': 'system',
          'amount': amount,
          'category': 'Transfers',
          'type': 'debit',
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Transfer money from Savings Vault back into Wallet.
  Future<bool> withdrawFromVault(double amount) async {
    if (_uid == null) return false;
    state = const AsyncLoading();
    try {
      await _db.runTransaction((txn) async {
        final userSnap = await txn.get(_userRef);
        final user = UserModel.fromFirestore(userSnap);

        if (user.savingsVault < amount) {
          throw Exception('Insufficient Vault balance');
        }

        // Move funds
        txn.update(_userRef, {
          'walletBalance': FieldValue.increment(amount),
          'savingsVault': FieldValue.increment(-amount),
        });

        // Record transaction
        final txnDoc = _txnRef.doc();
        txn.set(txnDoc, {
          'id': txnDoc.id,
          'title': 'Vault Withdrawal',
          'senderId': _uid,
          'receiverId': _uid,
          'amount': amount,
          'category': 'Savings',
          'type': 'credit',
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// Migrates users from 0 to 2000 credit if they have no history.
  Future<void> seedPulseCredit() async {
    if (_uid == null) return;
    try {
      final userSnap = await _userRef.get();
      final user = UserModel.fromFirestore(userSnap);

      if (user.isWalletActive && user.pulseCredit <= 0) {
        // Simple update - if they truly used it and have 0 left,
        // they can just repay. But if they never had it, they get 2000.
        // We assume 0 means 'not initialized' for this specific migration.
        await _userRef.update({'pulseCredit': MAX_CREDIT});
        print('--- [Wallet] Seeded Pulse Credit to $MAX_CREDIT ---');
      }
    } catch (e) {
      print('--- [Wallet] Credit seed failed: $e ---');
    }
  }

  /// Helper to run AI checks without blocking the main flow
  void _runAiGovernance(TransactionModel txn, double budget) {
    final history = _ref.read(transactionsStreamProvider).value ?? [];
    final notificationService = _ref.read(notificationServiceProvider);

    AiGovernanceService.detectFraud(
      uid: _uid!,
      transaction: txn,
      history: history,
      db: _db,
      notificationService: notificationService,
    );
    AiGovernanceService.checkBudgetAlert(
      uid: _uid!,
      monthlyBudget: budget,
      history: history,
      db: _db,
      notificationService: notificationService,
    );
  }
}
