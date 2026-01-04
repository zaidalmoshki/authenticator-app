import 'package:flutter/foundation.dart';

import '../models/token_entry.dart';

@immutable
class OtpAuthData {
  const OtpAuthData({
    required this.issuer,
    required this.account,
    required this.secretBase32,
    required this.digits,
    required this.period,
    required this.algorithm,
  });

  final String issuer;
  final String account;
  final String secretBase32;
  final int digits;
  final int period;
  final OtpAlgorithm algorithm;
}

class OtpAuthParser {
  static OtpAuthData parse(String uriString) {
    final uri = Uri.parse(uriString);
    if (uri.scheme != 'otpauth') {
      throw const FormatException('Invalid otpauth scheme');
    }
    if (uri.host != 'totp') {
      throw const FormatException('Only TOTP is supported');
    }

    final label = Uri.decodeComponent(uri.path.replaceFirst('/', ''));
    final query = uri.queryParameters;
    final secret = query['secret'];
    if (secret == null || secret.isEmpty) {
      throw const FormatException('Missing secret');
    }

    final issuerParam = query['issuer']?.trim();
    String issuer = issuerParam ?? '';
    String account = '';

    if (label.contains(':')) {
      final parts = label.split(':');
      if (issuer.isEmpty) {
        issuer = parts.first.trim();
      }
      account = parts.sublist(1).join(':').trim();
    } else {
      account = label.trim();
    }

    if (issuer.isEmpty) {
      issuer = 'Unknown';
    }

    final digits = int.tryParse(query['digits'] ?? '') ?? 6;
    final period = int.tryParse(query['period'] ?? '') ?? 30;
    final algorithmRaw = (query['algorithm'] ?? 'SHA1').toUpperCase();
    final algorithm = switch (algorithmRaw) {
      'SHA256' => OtpAlgorithm.sha256,
      'SHA512' => OtpAlgorithm.sha512,
      _ => OtpAlgorithm.sha1,
    };

    return OtpAuthData(
      issuer: issuer,
      account: account.isEmpty ? 'Account' : account,
      secretBase32: secret,
      digits: digits,
      period: period,
      algorithm: algorithm,
    );
  }
}
