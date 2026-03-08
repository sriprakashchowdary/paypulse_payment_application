import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_provider.dart';
import '../../models/card_model.dart';
import '../core/utils/card_utils.dart';

final cardProvider = StreamProvider<List<CardModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) {
    debugPrint('[DEBUG] cardProvider: uid is null, returning empty');
    return Stream.value([]);
  }

  debugPrint('[DEBUG] cardProvider: starting for UID: $uid');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('cards')
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
    debugPrint(
        '[DEBUG] cardProvider: got ${snapshot.docs.length} cards (from cache: ${snapshot.metadata.isFromCache})');
    return snapshot.docs.map((doc) => CardModel.fromFirestore(doc)).toList();
  });
});

final cardControllerProvider =
    StateNotifierProvider<CardController, AsyncValue<void>>((ref) {
  return CardController(ref);
});

class CardController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final _db = FirebaseFirestore.instance;

  CardController(this._ref) : super(const AsyncValue.data(null));

  /// Gets the current user's UID directly from Firebase Auth (fast, no Firestore round-trip).
  String? get _uid => _ref.read(authStateProvider).value?.uid;

  Future<bool> addCard(CardModel card) async {
    final uid = _uid;
    if (uid == null) {
      debugPrint('[ERROR] CardController: Cannot add card, _uid is null!');
      return false;
    }

    debugPrint('[DEBUG] CardController: Formatting card for UID: $uid');
    final normalizedCardNumber = CardUtils.formatCardNumber(card.cardNumber);
    final resolvedNetwork = CardUtils.getCardNetwork(normalizedCardNumber);
    final cardToSave = CardModel(
      id: card.id,
      cardNumber: normalizedCardNumber,
      lastFour: normalizedCardNumber.length >= 4
          ? normalizedCardNumber.substring(normalizedCardNumber.length - 4)
          : card.lastFour,
      expiryDate: card.expiryDate,
      cardholderName: card.cardholderName,
      network: resolvedNetwork,
      colors: card.colors,
      isFrozen: card.isFrozen,
      isDetailsVisible: card.isDetailsVisible,
      monthlyLimit: card.monthlyLimit,
      monthlySpent: card.monthlySpent,
    );

    state = const AsyncValue.loading();
    try {
      debugPrint('[DEBUG] CardController: Saving card to Firestore...');
      await _db
          .collection('users')
          .doc(uid)
          .collection('cards')
          .add(cardToSave.toFirestore());
      debugPrint('[DEBUG] CardController: Successfully saved card!');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('[ERROR] CardController addCard: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> deleteCard(String cardId) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('cards')
          .doc(cardId)
          .delete();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleFreeze(String cardId, bool currentStatus) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('cards')
          .doc(cardId)
          .update({'isFrozen': !currentStatus});
    } catch (e) {
      // Handle error
    }
  }

  Future<void> toggleDetailsVisibility(
      String cardId, bool currentStatus) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('cards')
          .doc(cardId)
          .update({'isDetailsVisible': !currentStatus});
    } catch (e) {
      // Handle error
    }
  }
}
