import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import 'secure_storage_service.dart';

class AppLockService {
  AppLockService({
    required SecureStorageService storageService,
    LocalAuthentication? localAuth,
  })  : _storageService = storageService,
        _localAuth = localAuth ?? LocalAuthentication();

  final SecureStorageService _storageService;
  final LocalAuthentication _localAuth;

  Future<bool> isBiometricsAvailable() async {
    try {
      final enrolled = await _localAuth.getAvailableBiometrics();
      if (enrolled.isNotEmpty) {
        return true;
      }
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock your authenticator',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storageService.savePinHash(hash: hash, salt: salt);
  }

  Future<bool> verifyPin(String pin) async {
    final (hash, salt) = await _storageService.loadPinHash();
    if (hash == null || salt == null) {
      return false;
    }
    return _hashPin(pin, salt) == hash;
  }

  Future<bool> hasPin() async {
    final (hash, salt) = await _storageService.loadPinHash();
    return hash != null && salt != null;
  }

  Future<void> clearPin() => _storageService.clearPin();

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin::$salt');
    return sha256.convert(bytes).toString();
  }
}
