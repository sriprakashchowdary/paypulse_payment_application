import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';

/// ══════════════════════════════════════════════════════════════
/// Gold Price Service — fetches live gold spot price from
/// the free MetalPriceAPI / GoldAPI.io fallback.
///
/// Uses frankfurter.app for XAU → INR conversion as a free,
/// no-key alternative.
/// ══════════════════════════════════════════════════════════════

// --- Data models ------------------------------------------------

class GoldPrice {
  final double pricePerGram; // INR per gram
  final double pricePerOunce; // INR per troy ounce
  final double change24h; // Percentage change 24h
  final DateTime updatedAt;

  const GoldPrice({
    required this.pricePerGram,
    required this.pricePerOunce,
    required this.change24h,
    required this.updatedAt,
  });
}

class GoldHolding {
  final double grams;
  final double investedAmount;

  const GoldHolding({this.grams = 0, this.investedAmount = 0});

  double currentValue(double pricePerGram) => grams * pricePerGram;
  double profitLoss(double pricePerGram) =>
      currentValue(pricePerGram) - investedAmount;
}

// --- Provider ---------------------------------------------------

final goldPriceProvider = FutureProvider<GoldPrice>((ref) async {
  return GoldPriceService.fetchPrice();
});

final goldHistoryProvider =
    FutureProvider<List<Map<String, double>>>((ref) async {
  return GoldPriceService.fetchHistory();
});

// --- Controller ---------------------------------------------------

final goldControllerProvider =
    StateNotifierProvider<GoldController, AsyncValue<void>>((ref) {
  return GoldController(ref);
});

class GoldController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  GoldController(this._ref) : super(const AsyncValue.data(null));

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> buyGold(double amountInr, double pricePerGram) async {
    final user = _ref.read(userDocProvider).value;
    if (user == null) throw Exception('User not authenticated');

    if (user.walletBalance < amountInr) {
      throw Exception('Insufficient wallet balance');
    }

    state = const AsyncValue.loading();
    try {
      final grams = amountInr / pricePerGram;

      final batch = _db.batch();
      final userRef = _db.collection('users').doc(user.uid);
      final txRef = _db.collection('transactions').doc();

      final goldCashback = (amountInr * 0.01).toDouble();

      // Use atomic increments to avoid race conditions
      batch.update(userRef, {
        'walletBalance': FieldValue.increment(-amountInr + goldCashback),
        'goldGrams': FieldValue.increment(grams),
        'goldInvested': FieldValue.increment(amountInr),
        'totalCashback': FieldValue.increment(goldCashback),
      });

      batch.set(txRef, {
        'title': 'Gold Purchase (${grams.toStringAsFixed(3)} gm)',
        'senderId': user.uid,
        'receiverId': 'GOLD_VAULT',
        'amount': amountInr,
        'category': 'Investment',
        'type': 'debit',
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Record cashback reward for gold purchase
      final rewardRef = _db.collection('transactions').doc();
      batch.set(rewardRef, {
        'title': 'Cashback Reward',
        'senderId': 'system',
        'receiverId': user.uid,
        'amount': goldCashback,
        'category': 'Rewards',
        'type': 'credit',
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print(
          'Gold Purchase Grams: $grams, Amount: $amountInr, Cashback: $goldCashback');
      await batch.commit();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw Exception(
          'Transaction failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> sellGold(double grams, double pricePerGram) async {
    final user = _ref.read(userDocProvider).value;
    if (user == null) throw Exception('User not authenticated');

    if (user.goldGrams < grams) {
      throw Exception('Insufficient gold balance');
    }

    state = const AsyncValue.loading();
    try {
      final amountInr = grams * pricePerGram;

      // Calculate reduction in invested amount proportionally
      final investedReduction = user.goldGrams > 0
          ? (grams / user.goldGrams) * user.goldInvested
          : 0.0;

      final batch = _db.batch();
      final userRef = _db.collection('users').doc(user.uid);
      final txRef = _db.collection('transactions').doc();

      // Use atomic increments to avoid race conditions
      batch.update(userRef, {
        'walletBalance': FieldValue.increment(amountInr),
        'goldGrams': FieldValue.increment(-grams),
        'goldInvested': FieldValue.increment(-investedReduction),
      });

      batch.set(txRef, {
        'title': 'Gold Sale (${grams.toStringAsFixed(3)} gm)',
        'senderId': 'GOLD_VAULT',
        'receiverId': user.uid,
        'amount': amountInr,
        'category': 'Investment',
        'type': 'credit',
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print(
          'Gold Sale Grams: $grams, Amount: $amountInr, Invested Reduction: $investedReduction');
      await batch.commit();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      throw Exception(
          'Transaction failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}

// --- Service ----------------------------------------------------

class GoldPriceService {
  /// Fetches today's gold price in INR per gram.
  /// Uses open exchange data: XAU/USD from Frankfurter + USD/INR.
  static Future<GoldPrice> fetchPrice() async {
    const apiKey = 'goldapi-5tsvsmlujh3ek-io';
    try {
      print('--- [GoldService] Fetching from GoldAPI.io... ---');
      final response = await http.get(
        Uri.parse('https://www.goldapi.io/api/XAU/INR'),
        headers: {
          'x-access-token': apiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('--- [GoldService] Status Code: ${response.statusCode} ---');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('--- [GoldService] Response: $data ---');
        final priceGram24k =
            (data['price_gram_24k'] as num?)?.toDouble() ?? 0.0;
        final priceOunce = (data['price'] as num?)?.toDouble() ?? 0.0;
        final chp = (data['chp'] as num?)?.toDouble() ?? 0.0;

        if (priceGram24k > 0) {
          return GoldPrice(
            pricePerGram: priceGram24k,
            pricePerOunce: priceOunce,
            change24h: chp,
            updatedAt: DateTime.now(),
          );
        }
      }

      // 2. Fallback to Frankfurter + GoldPrice.org if primary API fails
      final usdInrResp = await http.get(
        Uri.parse('https://api.frankfurter.app/latest?from=USD&to=INR'),
      );

      if (usdInrResp.statusCode == 200) {
        final usdInrData = jsonDecode(usdInrResp.body);
        // ignore: unused_local_variable
        final usdToInr =
            (usdInrData['rates']?['INR'] as num?)?.toDouble() ?? 83.0;

        final goldResp = await http.get(
          Uri.parse('https://data-asg.goldprice.org/dbXRates/INR'),
        );

        if (goldResp.statusCode == 200) {
          final goldData = jsonDecode(goldResp.body);
          final items = goldData['items'] as List?;
          if (items != null && items.isNotEmpty) {
            final ounceInr = (items[0]['xauPrice'] as num?)?.toDouble() ?? 0.0;
            if (ounceInr > 0) {
              return GoldPrice(
                pricePerGram: ounceInr / 31.1035,
                pricePerOunce: ounceInr,
                change24h: (items[0]['chgXau'] as num?)?.toDouble() ?? 0.0,
                updatedAt: DateTime.now(),
              );
            }
          }
        }
      }

      throw Exception('All gold price sources failed');
    } catch (e) {
      print('--- [GoldService] fetchPrice Error: $e ---');
      // Final hardcoded fallback for extreme cases
      return GoldPrice(
        pricePerGram: 7850,
        pricePerOunce: 7850 * 31.1035,
        change24h: 0.45,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Fetches 30-day gold price history for the chart.
  /// Returns list of {day: double, price: double}.
  static Future<List<Map<String, double>>> fetchHistory() async {
    try {
      // Get last 30 days USD/INR rates
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final from =
          '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
      final to =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final resp = await http.get(
        Uri.parse('https://api.frankfurter.app/$from..$to?from=XAU&to=INR'),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null) {
          final history = <Map<String, double>>[];
          var i = 0.0;
          final sortedKeys = rates.keys.toList()..sort();
          for (final date in sortedKeys) {
            final inrRate = (rates[date]['INR'] as num?)?.toDouble() ?? 0;
            if (inrRate > 0) {
              // XAU rate is per ounce, convert to per gram
              history.add({
                'day': i,
                'price': inrRate / 31.1035,
              });
              i++;
            }
          }
          return history;
        }
      }
    } catch (_) {
      // ignore and return simulated
    }

    // Simulated 30-day data if API fails
    return _simulatedHistory();
  }

  static List<Map<String, double>> _simulatedHistory() {
    const basePrice = 7850.0;
    final history = <Map<String, double>>[];
    for (var i = 0; i < 30; i++) {
      // Simulate realistic gold price movement
      final variation = (i * 17 % 7 - 3) * 12.0 + (i * 3.2);
      history.add({
        'day': i.toDouble(),
        'price': basePrice + variation,
      });
    }
    return history;
  }
}
