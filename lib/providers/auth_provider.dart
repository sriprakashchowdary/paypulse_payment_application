import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/services/email_service.dart';

// ═══════════════════════════════════════════════════════════════
//  FIREBASE INSTANCES
// ═══════════════════════════════════════════════════════════════

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

// ═══════════════════════════════════════════════════════════════
//  AUTH STATE STREAM
// ═══════════════════════════════════════════════════════════════

/// Streams the current Firebase Auth user (null = signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ═══════════════════════════════════════════════════════════════
//  USER DOCUMENT STREAM
// ═══════════════════════════════════════════════════════════════

/// Streams the signed-in user's Firestore document as UserModel.
final userDocProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        debugPrint('[DEBUG] userDocProvider: user is null');
        return Stream.value(null);
      }
      debugPrint('[DEBUG] userDocProvider: listening to users/${user.uid}');
      return ref
          .read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots(includeMetadataChanges: true)
          .map((snap) {
        if (!snap.exists) {
          debugPrint(
              '[DEBUG] userDocProvider: Document does not exist for UID: ${user.uid}');
          return null;
        }
        debugPrint(
            '[DEBUG] userDocProvider: Data received for UID: ${user.uid}');
        return UserModel.fromFirestore(snap);
      });
    },
    loading: () {
      debugPrint('[DEBUG] userDocProvider: auth state loading...');
      return Stream.value(null);
    },
    error: (e, s) {
      debugPrint('[ERROR] userDocProvider auth error: $e');
      return Stream.value(null);
    },
  );
});

// ═══════════════════════════════════════════════════════════════
//  AUTH STATE (loading / error / idle)
// ═══════════════════════════════════════════════════════════════

/// Holds the current auth operation state for UI feedback.
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

// ═══════════════════════════════════════════════════════════════
//  AUTH CONTROLLER
// ═══════════════════════════════════════════════════════════════

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthController(this._ref) : super(const AuthState());

  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  FirebaseStorage get _storage => _ref.read(firebaseStorageProvider);

  // ── OTP FLOW STATE ─────────────────────────────
  String? _pendingName;
  String? _pendingEmail;
  String? _pendingPassword;

  /// Current user UID or null.
  String? get currentUid => _auth.currentUser?.uid;

  /// Current user email or null.
  String? get currentUserEmail => _auth.currentUser?.email;

  // ── SEND OTP ───────────────────────────────────

  /// Generates a 6-digit OTP and stores it in Firestore for verification.
  /// In a production environment, this would trigger a cloud function to send an email.
  Future<bool> sendOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      _pendingName = name;
      _pendingEmail = email.trim();
      _pendingPassword = password;

      // 1. Generate 6-digit OTP
      final otp = (100000 + (DateTime.now().millisecond * 899) % 900000)
          .toString()
          .padLeft(6, '0');

      // 2. Save OTP to Firestore (collection: pending_verifications)
      print('--- ATTEMPTING TO WRITE TO FIRESTORE ---');
      await _db.collection('pending_verifications').doc(_pendingEmail).set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        print('--- FIRESTORE WRITE TIMEOUT ---');
        throw Exception(
            'Network timeout writing to database. Check your connection.');
      });
      print('--- SUCCESSFULLY WROTE TO FIRESTORE ---');

      // 3. Dispatch real email
      print('--- ATTEMPTING TO CALL EMAIL SERVICE ---');
      final emailSent = await EmailService.sendOtp(_pendingEmail!, otp);
      print('--- EMAIL SERVICE FINISHED: $emailSent ---');

      if (!emailSent) {
        state = const AuthState(
          error: 'Failed to send verification email. Please try again.',
        );
        return false;
      }

      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  // ── RESEND OTP ─────────────────────────────────

  /// Resends the OTP using the previously saved pending details.
  Future<bool> resendOtp() async {
    if (_pendingName == null ||
        _pendingEmail == null ||
        _pendingPassword == null) {
      state = const AuthState(
          error: 'Session expired. Please go back and sign up again.');
      return false;
    }

    return await sendOtp(
      name: _pendingName!,
      email: _pendingEmail!,
      password: _pendingPassword!,
    );
  }

  // ── VERIFY OTP & REGISTER ──────────────────────

  /// Verifies the OTP and proceeds with account creation.
  Future<bool> verifyOtp(String enteredOtp) async {
    if (_pendingEmail == null) return false;

    state = const AuthState(isLoading: true);
    try {
      // 1. Fetch the stored OTP
      final doc = await _db
          .collection('pending_verifications')
          .doc(_pendingEmail)
          .get();

      if (!doc.exists) {
        state = const AuthState(
          error: 'Verification session expired. Try again.',
        );
        return false;
      }

      final storedOtp = doc.data()?['otp'];
      // Check for expiration (e.g., 10 mins)
      final createdAt = (doc.data()?['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inMinutes > 10) {
        state = const AuthState(error: 'OTP has expired.');
        return false;
      }

      if (storedOtp != enteredOtp) {
        state = const AuthState(
          error: 'Invalid OTP code. Please check your email.',
        );
        return false;
      }

      // 2. OTP is valid! Proceed with actual registration.
      final success = await register(
        name: _pendingName!,
        email: _pendingEmail!,
        password: _pendingPassword!,
      );

      if (success) {
        // Cleanup
        await _db
            .collection('pending_verifications')
            .doc(_pendingEmail)
            .delete();
        _pendingName = null;
        _pendingEmail = null;
        _pendingPassword = null;
      }

      return success;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  // ── REGISTER ───────────────────────────────────

  /// Register with email/password + create Firestore user doc.
  ///
  /// On success: creates `users/{uid}` with schema:
  ///   uid, name, email, walletBalance(0), monthlyBudget(10000), createdAt
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      // 1. Create Firebase Auth account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (cred.user == null) {
        state = const AuthState(error: 'Account creation failed. Try again.');
        return false;
      }

      // 2. Update display name
      await cred.user!.updateDisplayName(name.trim());

      // 3. Create Firestore user document
      final userDoc = UserModel(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        walletBalance: 0,
        monthlyBudget: 10000,
        isWalletActive: false, // Initialize as false
        createdAt: DateTime.now(),
      );
      await _db
          .collection('users')
          .doc(cred.user!.uid)
          .set(userDoc.toFirestore());

      state = const AuthState(); // success — clear loading
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  // ── LOGIN ──────────────────────────────────────

  /// Sign in with email/password.
  Future<bool> login({required String email, required String password}) async {
    state = const AuthState(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  // ── FORGOT PASSWORD ────────────────────────────

  /// Send password reset email.
  Future<bool> resetPassword({required String email}) async {
    state = const AuthState(isLoading: true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      state = AuthState(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  /// Activates the user's wallet after KYC/OTP.
  Future<bool> activateWallet({
    required String phone,
    required String pin,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      state = const AuthState(error: 'Session expired. Please login again.');
      return false;
    }

    state = const AuthState(isLoading: true);
    try {
      await _db.collection('users').doc(uid).update({
        'isWalletActive': true,
        'phone': phone.trim(),
        'walletPin': pin.trim(),
        'pulseScore': 750, // Initial score
        'pulseCredit': 2000.0, // Initial credit limit
      });

      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  // ── UPDATE PROFILE ─────────────────────────────

  /// Updates the user's profile fields in Firestore `users/{uid}`.
  /// Only the provided (non-null) fields are written.
  /// Also syncs [name] to FirebaseAuth displayName for consistency.
  Future<bool> updateProfile({
    required String uid,
    required String name,
    String? phone,
    String? photoUrl,
    File? imageFile,
  }) async {
    state = const AuthState(isLoading: true);
    try {
      String? finalPhotoUrl = photoUrl;

      // 1. Upload image if provided
      if (imageFile != null) {
        print('--- [Auth] Starting Profile Image Upload ---');
        print('--- [Auth] Local Path: ${imageFile.path}');
        final storageRef = _storage.ref().child('profiles').child('$uid.png');
        print('--- [Auth] Storage Path: ${storageRef.fullPath}');

        // Using SettableMetadata can sometimes help with indexing speed
        final metadata = SettableMetadata(contentType: 'image/png');
        final uploadTask = await storageRef.putFile(imageFile, metadata);

        print('--- [Auth] Upload Finished. State: ${uploadTask.state} ---');
        print('--- [Auth] Bytes Transferred: ${uploadTask.totalBytes} ---');

        // Sometimes getDownloadURL fails with 'object-not-found' if called too quickly after upload
        finalPhotoUrl = await _getDownloadUrlWithRetry(storageRef);
        print(
            '--- [Auth] Successfully obtained Download URL: $finalPhotoUrl ---');
      }

      final Map<String, dynamic> updates = {
        'name': name.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (finalPhotoUrl != null && finalPhotoUrl.isNotEmpty)
          'photoUrl': finalPhotoUrl.trim(),
      };

      // 2. Write to Firestore and Firebase Auth displayName in parallel
      await Future.wait([
        _db.collection('users').doc(uid).update(updates),
        _auth.currentUser?.updateDisplayName(name.trim()) ?? Future.value(),
        if (finalPhotoUrl != null)
          _auth.currentUser?.updatePhotoURL(finalPhotoUrl) ?? Future.value(),
      ]);

      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  /// Helper to retry getDownloadURL if it fails with 'object-not-found'
  Future<String> _getDownloadUrlWithRetry(Reference ref,
      {int maxRetries = 5}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        // Try to get metadata first as a more lightweight check for existence
        print('--- [Auth] Checking for metadata for $attempts... ---');
        await ref.getMetadata();

        // If metadata succeeds, file exists, get download URL
        print('--- [Auth] Metadata found, fetching download URL... ---');
        return await ref.getDownloadURL();
      } catch (e) {
        attempts++;
        print('--- [Auth] Attempt $attempts failed: $e ---');

        if (attempts >= maxRetries) {
          print('--- [Auth] Max retries reached ---');
          rethrow;
        }

        // Increase delay even more: 2s, 4s, 6s...
        final delayMs = 2000 * attempts;
        print('--- [Auth] Retrying in ${delayMs}ms... ---');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    throw Exception('Failed to get download URL after $maxRetries retries');
  }

  // ── DELETE ACCOUNT ───────────────────────────

  /// Deletes the user's account, taking care of transferring remaining money to an active card.
  Future<bool> deleteAccount() async {
    final userAuth = _auth.currentUser;
    final uid = userAuth?.uid;

    if (userAuth == null || uid == null) {
      state = const AuthState(error: 'Session expired. Please login again.');
      return false;
    }

    state = const AuthState(isLoading: true);
    try {
      final userDocRef = _db.collection('users').doc(uid);
      final userSnap = await userDocRef.get();

      if (userSnap.exists) {
        final userData = userSnap.data()!;
        final balance = (userData['walletBalance'] as num?)?.toDouble() ?? 0.0;

        // Auto refund balance if positive.
        if (balance > 0) {
          // Check for available cards to simulate refund
          final cardsQuery =
              await userDocRef.collection('cards').limit(1).get();

          if (cardsQuery.docs.isNotEmpty) {
            // Simulate withdrawal
            final cardData = cardsQuery.docs.first.data();
            final last4 = cardData['cardNumber']?.toString().substring(
                    cardData['cardNumber'].toString().length > 4
                        ? cardData['cardNumber'].toString().length - 4
                        : 0) ??
                'Card';

            await _db.collection('transactions').add({
              'title': 'Account Closure Refund (to *$last4)',
              'senderId': uid,
              'receiverId': 'bank', // External entity
              'amount': balance,
              'category': 'Refund',
              'type': 'refund',
              'status': 'completed',
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
          // The money is "sent back", now zero out the balance officially just in case
          await userDocRef.update({'walletBalance': 0.0});
        }

        // Delete the user's document
        await userDocRef.delete();
      }

      // Finally sequence the Auth identity deletion
      await userAuth.delete();

      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        state = const AuthState(
            error:
                'For security, please sign out, sign back in, and try deleting your account again.');
      } else {
        state = AuthState(error: _mapAuthError(e.code));
      }
      return false;
    } catch (e) {
      state = AuthState(error: 'Failed to delete account: $e');
      return false;
    }
  }

  // ── LOGOUT ─────────────────────────────────────

  /// Sign out the current user.
  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState();
  }

  // ── CLEAR ERROR ────────────────────────────────

  /// Dismiss the current error message.
  void clearError() {
    state = const AuthState();
  }

  // ── ERROR MAPPING ──────────────────────────────

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Check your email and password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
