import 'package:totp/totp.dart';

import '../models/token_entry.dart';

class TotpService {
  String generate(TokenEntry entry, {DateTime? time}) {
    final algorithm = switch (entry.algorithm) {
      OtpAlgorithm.sha256 => Algorithm.SHA256,
      OtpAlgorithm.sha512 => Algorithm.SHA512,
      _ => Algorithm.SHA1,
    };

    return TOTP.generate(
      entry.secretBase32,
      algorithm: algorithm,
      interval: entry.periodSeconds,
      length: entry.digits,
      timestamp: (time ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  double progress(TokenEntry entry, DateTime now) {
    final seconds = now.millisecondsSinceEpoch / 1000.0;
    final remainder = seconds % entry.periodSeconds;
    return remainder / entry.periodSeconds;
  }

  int remaining(TokenEntry entry, DateTime now) {
    final seconds = now.millisecondsSinceEpoch ~/ 1000;
    final elapsed = seconds % entry.periodSeconds;
    return entry.periodSeconds - elapsed;
  }
}
