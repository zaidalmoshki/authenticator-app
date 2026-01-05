import 'package:totp/totp.dart';

import '../models/token_entry.dart';

class TotpService {
  String generate(TokenEntry entry, {DateTime? time}) {
    final algorithm = switch (entry.algorithm) {
      OtpAlgorithm.sha256 => Algorithm.sha256,
      OtpAlgorithm.sha512 => Algorithm.sha512,
      _ => Algorithm.sha1,
    };

    final totp = Totp.fromBase32(
      secret: entry.secretBase32,
      algorithm: algorithm,
      digits: entry.digits,
      period: entry.periodSeconds,
    );

    return totp.generate(time ?? DateTime.now());
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
