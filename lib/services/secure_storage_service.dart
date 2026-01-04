import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/app_settings.dart';
import '../models/token_entry.dart';

class SecureStorageService {
  static const _tokensKey = 'tokens';
  static const _settingsKey = 'settings';
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<List<TokenEntry>> loadTokens() async {
    final raw = await _storage.read(key: _tokensKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => TokenEntry.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveTokens(List<TokenEntry> tokens) async {
    final payload = jsonEncode(tokens.map((e) => e.toJson()).toList());
    await _storage.write(key: _tokensKey, value: payload);
  }

  Future<AppSettings> loadSettings() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _storage.write(key: _settingsKey, value: jsonEncode(settings.toJson()));
  }

  Future<void> savePinHash({required String hash, required String salt}) async {
    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
  }

  Future<(String?, String?)> loadPinHash() async {
    final hash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    return (hash, salt);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }
}
