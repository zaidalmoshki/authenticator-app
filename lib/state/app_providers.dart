import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import '../models/app_settings.dart';
import '../models/token_entry.dart';
import '../services/app_lock_service.dart';
import '../services/app_lock_policy.dart';
import '../services/secure_storage_service.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._storage) : super(AppSettings.defaults()) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    final loaded = await _storage.loadSettings();
    emit(loaded);
  }

  Future<void> update(AppSettings settings) async {
    emit(settings);
    await _storage.saveSettings(settings);
  }
}

class TokensCubit extends Cubit<List<TokenEntry>> {
  TokensCubit(this._storage) : super(const []) {
    _load();
  }

  final SecureStorageService _storage;

  Future<void> _load() async {
    final tokens = await _storage.loadTokens();
    emit(tokens);
  }

  Future<void> addToken(TokenEntry entry) async {
    final updated = [...state, entry];
    emit(updated);
    await _storage.saveTokens(updated);
  }

  Future<void> removeToken(String id) async {
    final updated = state.where((token) => token.id != id).toList(growable: false);
    emit(updated);
    await _storage.saveTokens(updated);
  }

  Future<void> updateToken(TokenEntry entry) async {
    final updated = [
      for (final token in state)
        if (token.id == entry.id) entry else token,
    ];
    emit(updated);
    await _storage.saveTokens(updated);
  }
}

@immutable
class AppLockState extends Equatable {
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

  @override
  List<Object?> get props => [
        isLocked,
        biometricsAvailable,
        lockoutUntil,
        failedAttempts,
        hasPin,
      ];

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

class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(this._service, {AppSettings? initialSettings})
      : _settings = initialSettings ?? AppSettings.defaults(),
        super(const AppLockState(
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
    emit(state.copyWith(
      biometricsAvailable: biometricsAvailable,
      hasPin: hasPin,
    ));
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
    if (!_settings.appLockEnabled) {
      emit(state.copyWith(isLocked: false, failedAttempts: 0, lockoutUntil: null));
    }
  }

  Future<void> refreshBiometricsAvailability() async {
    final available = await _service.isBiometricsAvailable();
    emit(state.copyWith(biometricsAvailable: available));
  }

  void lock() {
    if (_settings.appLockEnabled) {
      emit(state.copyWith(isLocked: true));
    }
  }

  Future<bool> tryBiometricUnlock() async {
    if (!_settings.biometricsEnabled || !state.biometricsAvailable) {
      return false;
    }
    final success = await _service.authenticateWithBiometrics();
    if (success) {
      _resetFailures();
      emit(state.copyWith(isLocked: false));
      return true;
    }
    return false;
  }

  Duration? currentBackoff() {
    final until = state.lockoutUntil;
    if (until == null) return null;
    final now = DateTime.now();
    if (now.isAfter(until)) {
      emit(state.copyWith(lockoutUntil: null));
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
      emit(state.copyWith(isLocked: false));
      return true;
    }
    _registerFailure();
    return false;
  }

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    emit(state.copyWith(hasPin: true));
  }

  Future<void> clearPin() async {
    await _service.clearPin();
    emit(state.copyWith(hasPin: false));
  }

  void _registerFailure() {
    final failures = state.failedAttempts + 1;
    emit(state.copyWith(
      failedAttempts: failures,
      lockoutUntil: AppLockPolicy.lockoutUntil(DateTime.now(), failures),
    ));
  }

  void _resetFailures() {
    emit(state.copyWith(failedAttempts: 0, lockoutUntil: null));
  }
}
