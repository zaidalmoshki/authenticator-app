import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/token_entry.dart';
import '../services/app_lock_service.dart';
import '../services/app_lock_policy.dart';
import '../services/clipboard_service.dart';
import '../services/secure_storage_service.dart';
import '../services/totp_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final totpServiceProvider = Provider<TotpService>((ref) {
  return TotpService();
});

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService();
  ref.onDispose(service.dispose);
  return service;
});

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(storageService: ref.read(secureStorageProvider));
});

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.read(secureStorageProvider));
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._storage) : super(AppSettings.defaults()) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    state = await _storage.loadSettings();
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _storage.saveSettings(settings);
  }
}

final tokensProvider = StateNotifierProvider<TokensController, List<TokenEntry>>((ref) {
  return TokensController(ref.read(secureStorageProvider));
});

class TokensController extends StateNotifier<List<TokenEntry>> {
  TokensController(this._storage) : super(const []) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    state = await _storage.loadTokens();
  }

  Future<void> add(TokenEntry entry) async {
    final updated = [...state, entry];
    state = updated;
    await _storage.saveTokens(updated);
  }

  Future<void> remove(String id) async {
    final updated = state.where((token) => token.id != id).toList(growable: false);
    state = updated;
    await _storage.saveTokens(updated);
  }

  Future<void> updateToken(TokenEntry entry) async {
    final updated = [
      for (final token in state)
        if (token.id == entry.id) entry else token,
    ];
    state = updated;
    await _storage.saveTokens(updated);
  }
}

@immutable
class AppLockState {
  const AppLockState({
    required this.isLocked,
    required this.biometricsAvailable,
    required this.lockoutUntil,
    required this.failedAttempts,
    required this.hasPin,
  });

  final bool isLocked;
  final bool biometricsAvailable;
  final DateTime? lockoutUntil;
  final int failedAttempts;
  final bool hasPin;

  AppLockState copyWith({
    bool? isLocked,
    bool? biometricsAvailable,
    DateTime? lockoutUntil,
    int? failedAttempts,
    bool? hasPin,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      lockoutUntil: lockoutUntil,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

final appLockProvider = StateNotifierProvider<AppLockController, AppLockState>((ref) {
  return AppLockController(
    ref.read(appLockServiceProvider),
    ref.read(settingsProvider),
  );
});

class AppLockController extends StateNotifier<AppLockState> {
  AppLockController(this._service, this._settings)
      : super(const AppLockState(
          isLocked: false,
          biometricsAvailable: false,
          lockoutUntil: null,
          failedAttempts: 0,
          hasPin: false,
        )) {
    _init();
  }

  final AppLockService _service;
  AppSettings _settings;

  Future<void> _init() async {
    final biometricsAvailable = await _service.isBiometricsAvailable();
    final hasPin = await _service.hasPin();
    state = state.copyWith(
      biometricsAvailable: biometricsAvailable,
      hasPin: hasPin,
    );
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
    if (!_settings.appLockEnabled) {
      state = state.copyWith(isLocked: false, failedAttempts: 0, lockoutUntil: null);
    }
  }

  Future<void> refreshBiometricsAvailability() async {
    final available = await _service.isBiometricsAvailable();
    state = state.copyWith(biometricsAvailable: available);
  }

  void lock() {
    if (_settings.appLockEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  Future<bool> tryBiometricUnlock() async {
    if (!_settings.biometricsEnabled || !state.biometricsAvailable) {
      return false;
    }
    final success = await _service.authenticateWithBiometrics();
    if (success) {
      _resetFailures();
      state = state.copyWith(isLocked: false);
      return true;
    }
    return false;
  }

  Duration? currentBackoff() {
    final until = state.lockoutUntil;
    if (until == null) return null;
    final now = DateTime.now();
    if (now.isAfter(until)) {
      state = state.copyWith(lockoutUntil: null);
      return null;
    }
    return until.difference(now);
  }

  Future<bool> verifyPin(String pin) async {
    if (currentBackoff() != null) {
      return false;
    }
    final valid = await _service.verifyPin(pin);
    if (valid) {
      _resetFailures();
      state = state.copyWith(isLocked: false);
      return true;
    }
    _registerFailure();
    return false;
  }

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    state = state.copyWith(hasPin: true);
  }

  Future<void> clearPin() async {
    await _service.clearPin();
    state = state.copyWith(hasPin: false);
  }

  void _registerFailure() {
    final failures = state.failedAttempts + 1;
    state = state.copyWith(
      failedAttempts: failures,
      lockoutUntil: AppLockPolicy.lockoutUntil(DateTime.now(), failures),
    );
  }

  void _resetFailures() {
    state = state.copyWith(failedAttempts: 0, lockoutUntil: null);
  }
}
