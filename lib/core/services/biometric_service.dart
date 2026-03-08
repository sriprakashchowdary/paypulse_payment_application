import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Service that interacts natively with local authentication mechanisms
class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      return isAvailable && isSupported;
    } on PlatformException catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason:
            'Secure your PayPulse wallet with your fingerprint, face, or device PIN.',
      );
    } on PlatformException catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
