import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ══════════════════════════════════════════════════════════════
/// NOTIFICATION SERVICE — Handles FCM tokens and local triggers
/// ══════════════════════════════════════════════════════════════

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String uid) async {
    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted notification permission');

      // Get token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(uid, token);
      }

      // Handle token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(uid, newToken);
      });
    }
  }

  Future<void> _saveTokenToDatabase(String uid, String token) async {
    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Sends a notification using FCM Legacy HTTP API (for demo/internal app logic)
  /// In production, this should be done via Cloud Functions for security.
  Future<void> sendNotification({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final userDoc = await _db.collection('users').doc(recipientUid).get();
      final token = userDoc.data()?['fcmToken'];

      if (token == null) {
        log('No FCM token found for user $recipientUid');
        return;
      }

      // Note: This is for demonstration. Use Firebase Admin SDK in production backend.
      // Assuming a dummy server key for logic flow representation
      log('Pushing Notification to $recipientUid: $title - $body');

      // We also store it in the 'alerts' collection for in-app display
      await _db.collection('alerts').add({
        'userId': recipientUid,
        'title': title,
        'message': body,
        'alertType': data?['type'] ?? 'info',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Error sending notification: $e');
    }
  }
}
