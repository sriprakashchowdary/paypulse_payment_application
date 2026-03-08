import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier tracking whether the current live session has successfully
/// passed the biometric layer (if enabled). Defaults to false on app load.
class BiometricAuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void markAuthenticated() {
    state = true;
  }

  void markUnauthenticated() {
    state = false;
  }
}

final biometricAuthStateProvider =
    NotifierProvider<BiometricAuthNotifier, bool>(
  BiometricAuthNotifier.new,
);
