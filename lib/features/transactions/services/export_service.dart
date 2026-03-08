import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/auth_provider.dart';

/// ══════════════════════════════════════════════════════════════
/// Export Service — fetches all user transactions, builds CSV,
/// and triggers the native share / save sheet via share_plus.
/// ══════════════════════════════════════════════════════════════

final exportServiceProvider = Provider<ExportService>((ref) {
  final db = ref.watch(firestoreProvider);
  final uid = ref.watch(authStateProvider).value?.uid;
  return ExportService(db: db, uid: uid);
});

class ExportService {
  final FirebaseFirestore db;
  final String? uid;

  ExportService({required this.db, required this.uid});

  // ── Fetch ─────────────────────────────────────────────────────

  /// Fetches ALL transactions where the user is sender or receiver.
  /// Uses two separate queries to avoid needing a composite Firestore index.
  Future<List<TransactionModel>> fetchAllTransactions() async {
    if (uid == null) return [];

    // Transactions where user is the sender
    final sentFuture =
        db.collection('transactions').where('senderId', isEqualTo: uid).get();

    // Transactions where user is the receiver
    final receivedFuture =
        db.collection('transactions').where('receiverId', isEqualTo: uid).get();

    final results = await Future.wait([sentFuture, receivedFuture]);

    // Merge, deduplicate by doc ID, sort newest-first
    final all = <String, TransactionModel>{};
    for (final snap in results) {
      for (final doc in snap.docs) {
        all[doc.id] = TransactionModel.fromFirestore(doc);
      }
    }

    final sorted = all.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sorted;
  }

  // ── CSV ───────────────────────────────────────────────────────

  /// Converts a list of transactions to a well-formed CSV string.
  String buildCsv(List<TransactionModel> transactions) {
    final sb = StringBuffer();

    // Header row
    sb.writeln(
      'ID,Date,Time,Title,Type,Category,Amount (₹),Status,Sent To / Received From',
    );

    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm:ss');

    for (final t in transactions) {
      final isCredit = t.receiverId == uid;
      final counterparty = isCredit ? t.senderId : t.receiverId;

      // Escape any commas / quotes inside string fields
      String esc(String? s) {
        if (s == null || s.isEmpty) return '';
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }

      sb.writeln([
        esc(t.id),
        dateFmt.format(t.timestamp),
        timeFmt.format(t.timestamp),
        esc(t.title ?? 'Transaction'),
        isCredit ? 'Credit' : 'Debit',
        esc(t.category),
        t.amount.toStringAsFixed(2),
        esc(t.status),
        esc(counterparty),
      ].join(','));
    }

    return sb.toString();
  }

  // ── Export ────────────────────────────────────────────────────

  /// Full pipeline: fetch → build CSV → write temp file → share sheet.
  /// Returns [ExportResult] so the caller can show success / error UI.
  Future<ExportResult> export() async {
    try {
      // 1. Fetch
      final transactions = await fetchAllTransactions();

      if (transactions.isEmpty) {
        return ExportResult.empty();
      }

      // 2. Build CSV
      final csv = buildCsv(transactions);

      // 3. Write to temp file
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/paypulse_transactions_$stamp.csv');
      await file.writeAsString(csv, flush: true);

      // 4. Share via native sheet
      final xFile = XFile(
        file.path,
        mimeType: 'text/csv',
        name: 'paypulse_transactions_$stamp.csv',
      );

      await Share.shareXFiles(
        [xFile],
        subject: 'PayPulse — Transaction History',
        text:
            'My PayPulse transaction history export (${transactions.length} records).',
      );

      return ExportResult.success(count: transactions.length);
    } catch (e) {
      return ExportResult.failure(error: e.toString());
    }
  }
}

// ══════════════════════════════════════════════════════════════
// Result type
// ══════════════════════════════════════════════════════════════

enum ExportStatus { success, empty, failure }

class ExportResult {
  final ExportStatus status;
  final int count;
  final String? error;

  const ExportResult._({
    required this.status,
    this.count = 0,
    this.error,
  });

  factory ExportResult.success({required int count}) =>
      ExportResult._(status: ExportStatus.success, count: count);

  factory ExportResult.empty() =>
      const ExportResult._(status: ExportStatus.empty);

  factory ExportResult.failure({required String error}) =>
      ExportResult._(status: ExportStatus.failure, error: error);
}
