import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.appLockEnabled,
    required this.biometricsEnabled,
    required this.clipboardAutoClear,
    required this.screenshotProtection,
    required this.themeMode,
  });

  final bool appLockEnabled;
  final bool biometricsEnabled;
  final bool clipboardAutoClear;
  final bool screenshotProtection;
  final ThemeMode themeMode;

  factory AppSettings.defaults() => const AppSettings(
        appLockEnabled: false,
        biometricsEnabled: true,
        clipboardAutoClear: true,
        screenshotProtection: true,
        themeMode: ThemeMode.system,
      );

  AppSettings copyWith({
    bool? appLockEnabled,
    bool? biometricsEnabled,
    bool? clipboardAutoClear,
    bool? screenshotProtection,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      clipboardAutoClear: clipboardAutoClear ?? this.clipboardAutoClear,
      screenshotProtection: screenshotProtection ?? this.screenshotProtection,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'appLockEnabled': appLockEnabled,
        'biometricsEnabled': biometricsEnabled,
        'clipboardAutoClear': clipboardAutoClear,
        'screenshotProtection': screenshotProtection,
        'themeMode': themeMode.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      appLockEnabled: json['appLockEnabled'] as bool? ?? false,
      biometricsEnabled: json['biometricsEnabled'] as bool? ?? true,
      clipboardAutoClear: json['clipboardAutoClear'] as bool? ?? true,
      screenshotProtection: json['screenshotProtection'] as bool? ?? true,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
    );
  }
}
