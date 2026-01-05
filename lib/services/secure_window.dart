import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channelName = 'com.example.authenticator_app/secure_window';

/// Simple bridge for toggling Android's FLAG_SECURE to block screenshots.
class SecureWindow {
  static const _channel = MethodChannel(_channelName);

  static Future<void> setSecureFlag(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod(
        enabled ? 'enableSecureFlag' : 'disableSecureFlag',
      );
    } on PlatformException catch (error) {
      debugPrint('SecureWindow: failed to update flag (${error.code}): ${error.message}');
    }
  }
}
