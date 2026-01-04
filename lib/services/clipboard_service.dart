import 'dart:async';

import 'package:flutter/services.dart';

class ClipboardService {
  Timer? _timer;

  Future<void> copyOtp(String otp, {required bool autoClear}) async {
    await Clipboard.setData(ClipboardData(text: otp));
    _timer?.cancel();
    if (autoClear) {
      _timer = Timer(const Duration(seconds: 30), () async {
        await Clipboard.setData(const ClipboardData(text: ''));
      });
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
